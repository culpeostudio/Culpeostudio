package metasearch

import (
	"context"
	"crypto/tls"
	"crypto/x509"
	"fmt"
	"io"
	"net"
	"net/http"
	"net/http/cookiejar"
	"net/url"
	"os"
	"strings"
	"time"

	"golang.org/x/net/proxy"
)

type ClientOptions struct {
	Proxy   string
	Timeout time.Duration
	Verify  any
}

type HttpClient struct {
	client  *http.Client
	jar     http.CookieJar
	headers map[string]string
}

type Response struct {
	StatusCode int
	Content    []byte
	Text       string
}

type RequestParams struct {
	Method  string
	URL     string
	Params  map[string]string
	Data    map[string]string
	Headers map[string]string
}

func NewHttpClient(opts ClientOptions) (*HttpClient, error) {
	transport := &http.Transport{
		MaxIdleConns:        20,
		IdleConnTimeout:     90 * time.Second,
		TLSHandshakeTimeout: 10 * time.Second,
		TLSClientConfig:     &tls.Config{},
		ForceAttemptHTTP2:   true,
	}

	switch v := opts.Verify.(type) {
	case bool:
		if !v {
			transport.TLSClientConfig.InsecureSkipVerify = true
		}
	case string:
		if v == "" {

		} else {
			caCert, err := os.ReadFile(v)
			if err != nil {
				return nil, fmt.Errorf("metasearch: ca cert lesen: %w", err)
			}
			pool := x509.NewCertPool()
			if !pool.AppendCertsFromPEM(caCert) {
				return nil, fmt.Errorf("metasearch: pem-datei %s enthaelt keine gueltigen CAs", v)
			}
			transport.TLSClientConfig.RootCAs = pool
		}
	default:

	}

	proxyURL := strings.TrimSpace(opts.Proxy)
	if proxyURL != "" {
		p, err := url.Parse(proxyURL)
		if err != nil {
			return nil, fmt.Errorf("metasearch: proxy-url: %w", err)
		}
		switch p.Scheme {
		case "http", "https":
			transport.Proxy = http.ProxyURL(p)
		case "socks5", "socks5h":
			var auth *proxy.Auth
			if p.User != nil {
				pw, _ := p.User.Password()
				auth = &proxy.Auth{User: p.User.Username(), Password: pw}
			}
			dialer, err := proxy.SOCKS5("tcp", p.Host, auth, proxy.Direct)
			if err != nil {
				return nil, fmt.Errorf("metasearch: socks5: %w", err)
			}
			transport.DialContext = dialer.(interface {
				DialContext(ctx context.Context, network, addr string) (net.Conn, error)
			}).DialContext
		default:
			return nil, fmt.Errorf("metasearch: nicht unterstuetztes proxy-schema %q", p.Scheme)
		}
	}

	jar, err := cookiejar.New(nil)
	if err != nil {
		return nil, fmt.Errorf("metasearch: cookie jar: %w", err)
	}

	client := &http.Client{
		Transport: transport,
		Jar:       jar,

		CheckRedirect: func(req *http.Request, via []*http.Request) error {
			if len(via) >= 10 {
				return fmt.Errorf("metasearch: zu viele redirects")
			}
			if proxyURL != "" {
				switch strings.ToLower(req.URL.Scheme) {
				case "http", "https":
					return nil
				default:
					return fmt.Errorf("%w: redirect-schema %q", ErrBlockedURL, req.URL.Scheme)
				}
			}
			return GuardPublicURL(req.Context(), req.URL.String())
		},
	}
	if opts.Timeout > 0 {
		client.Timeout = opts.Timeout
	}

	return &HttpClient{
		client:  client,
		jar:     jar,
		headers: map[string]string{},
	}, nil
}

func (c *HttpClient) SetHeader(key, value string) {
	c.headers[key] = value
}

func (c *HttpClient) SetCookies(rawURL string, cookies map[string]string) error {
	u, err := url.Parse(rawURL)
	if err != nil {
		return err
	}
	httpCookies := make([]*http.Cookie, 0, len(cookies))
	for k, v := range cookies {
		httpCookies = append(httpCookies, &http.Cookie{Name: k, Value: v})
	}
	c.jar.SetCookies(u, httpCookies)
	return nil
}

func (c *HttpClient) Request(ctx context.Context, params RequestParams) (*Response, error) {
	if ctx == nil {
		ctx = context.Background()
	}

	finalURL := params.URL
	if len(params.Params) > 0 {
		v := url.Values{}
		for k, val := range params.Params {
			v.Set(k, val)
		}
		finalURL = params.URL + "?" + v.Encode()
	}

	var bodyReader io.Reader
	if len(params.Data) > 0 {
		v := url.Values{}
		for k, val := range params.Data {
			v.Set(k, val)
		}
		bodyReader = strings.NewReader(v.Encode())
	}

	method := strings.ToUpper(params.Method)
	if method == "" {
		method = "GET"
	}

	req, err := http.NewRequestWithContext(ctx, method, finalURL, bodyReader)
	if err != nil {
		return nil, NewError(err, "request bauen")
	}

	if len(params.Data) > 0 {
		req.Header.Set("Content-Type", "application/x-www-form-urlencoded")
	}

	for k, v := range c.headers {
		req.Header.Set(k, v)
	}

	for k, v := range params.Headers {
		req.Header.Set(k, v)
	}

	if req.Header.Get("User-Agent") == "" {
		req.Header.Set("User-Agent", defaultUserAgent())
	}

	if req.Header.Get("Accept") == "" {
		req.Header.Set("Accept", "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8")
	}
	if req.Header.Get("Accept-Language") == "" {
		req.Header.Set("Accept-Language", "en-US,en;q=0.9")
	}

	resp, err := c.client.Do(req)
	if err != nil {
		if ctx.Err() != nil {
			return nil, NewError(ctx.Err(), "timeout/kontext")
		}
		return nil, NewError(err, "request ausfuehren")
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(io.LimitReader(resp.Body, 32*1024*1024))
	if err != nil {
		return nil, NewError(err, "body lesen")
	}

	return &Response{
		StatusCode: resp.StatusCode,
		Content:    body,
		Text:       string(body),
	}, nil
}

func (c *HttpClient) Get(ctx context.Context, rawURL string, params map[string]string) (*Response, error) {
	return c.Request(ctx, RequestParams{Method: "GET", URL: rawURL, Params: params})
}

func (c *HttpClient) GetGuarded(ctx context.Context, rawURL string, params map[string]string) (*Response, error) {
	if ctx == nil {
		ctx = context.Background()
	}
	if err := GuardPublicURL(ctx, rawURL); err != nil {
		return nil, err
	}
	return c.Get(ctx, rawURL, params)
}

func (c *HttpClient) Post(ctx context.Context, rawURL string, data map[string]string) (*Response, error) {
	return c.Request(ctx, RequestParams{Method: "POST", URL: rawURL, Data: data})
}

func defaultUserAgent() string {
	return "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36"
}
