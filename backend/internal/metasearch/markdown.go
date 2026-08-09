package metasearch

import (
	"regexp"
	"strconv"
	"strings"

	"golang.org/x/net/html"
)

func HTMLToMarkdown(htmlText string) string {
	doc, err := html.Parse(strings.NewReader(htmlText))
	if err != nil {
		return NormalizeText(htmlText)
	}
	var b strings.Builder
	renderMarkdown(&b, doc, 0)
	out := b.String()
	out = collapseBlankLines(out)
	return strings.TrimSpace(out)
}

func renderMarkdown(b *strings.Builder, n *html.Node, depth int) {
	if n == nil || depth > 10000 {
		return
	}
	switch n.Type {
	case html.DocumentNode:
		for c := n.FirstChild; c != nil; c = c.NextSibling {
			renderMarkdown(b, c, depth+1)
		}
	case html.ElementNode:
		renderElement(b, n, depth)
	case html.TextNode:
		text := collapseWhitespace(html.UnescapeString(n.Data))
		if text != "" {
			b.WriteString(text)
		}
	case html.CommentNode:

	}
}

func renderElement(b *strings.Builder, n *html.Node, depth int) {
	switch n.Data {
	case "script", "style", "noscript", "iframe", "svg", "math", "template":
		return
	case "br":
		b.WriteString("\n")
		return
	case "hr":
		b.WriteString("\n---\n")
		return
	case "img":
		alt := getAttr(n, "alt")
		src := getAttr(n, "src")
		if src == "" {
			return
		}
		if alt != "" {
			b.WriteString("![")
			b.WriteString(alt)
			b.WriteString("](")
			b.WriteString(src)
			b.WriteString(")")
		} else {
			b.WriteString("!(")
			b.WriteString(src)
			b.WriteString(")")
		}
		return
	}

	switch n.Data {
	case "h1", "h2", "h3", "h4", "h5", "h6":
		level := int(n.Data[1] - '0')
		b.WriteString("\n\n")
		b.WriteString(strings.Repeat("#", level))
		b.WriteString(" ")
		for c := n.FirstChild; c != nil; c = c.NextSibling {
			renderMarkdown(b, c, depth+1)
		}
		b.WriteString("\n\n")
	case "p":
		b.WriteString("\n\n")
		for c := n.FirstChild; c != nil; c = c.NextSibling {
			renderMarkdown(b, c, depth+1)
		}
		b.WriteString("\n\n")
	case "a":
		href := getAttr(n, "href")
		b.WriteString("[")
		for c := n.FirstChild; c != nil; c = c.NextSibling {
			renderMarkdown(b, c, depth+1)
		}
		b.WriteString("](")
		b.WriteString(href)
		b.WriteString(")")
	case "strong", "b":
		b.WriteString("**")
		for c := n.FirstChild; c != nil; c = c.NextSibling {
			renderMarkdown(b, c, depth+1)
		}
		b.WriteString("**")
	case "em", "i":
		b.WriteString("*")
		for c := n.FirstChild; c != nil; c = c.NextSibling {
			renderMarkdown(b, c, depth+1)
		}
		b.WriteString("*")
	case "code":
		b.WriteString("`")
		for c := n.FirstChild; c != nil; c = c.NextSibling {
			renderMarkdown(b, c, depth+1)
		}
		b.WriteString("`")
	case "pre":
		b.WriteString("\n```\n")
		writePreText(b, n)
		b.WriteString("\n```\n\n")
	case "ul":
		b.WriteString("\n")
		for c := n.FirstChild; c != nil; c = c.NextSibling {
			if c.Type == html.ElementNode && c.Data == "li" {
				renderListItem(b, c, false, 0)
			}
		}
		b.WriteString("\n")
	case "ol":
		b.WriteString("\n")
		idx := 1
		for c := n.FirstChild; c != nil; c = c.NextSibling {
			if c.Type == html.ElementNode && c.Data == "li" {
				renderListItem(b, c, true, idx)
				idx++
			}
		}
		b.WriteString("\n")
	case "blockquote":
		b.WriteString("\n> ")
		for c := n.FirstChild; c != nil; c = c.NextSibling {
			renderMarkdown(b, c, depth+1)
		}
		b.WriteString("\n\n")
	case "div", "section", "article", "main", "header", "footer", "nav", "aside":
		b.WriteString("\n")
		for c := n.FirstChild; c != nil; c = c.NextSibling {
			renderMarkdown(b, c, depth+1)
		}
		b.WriteString("\n")
	default:
		for c := n.FirstChild; c != nil; c = c.NextSibling {
			renderMarkdown(b, c, depth+1)
		}
	}
}

func renderListItem(b *strings.Builder, li *html.Node, ordered bool, idx int) {
	marker := "- "
	if ordered {
		marker = strconv.Itoa(idx) + ". "
	}
	b.WriteString(marker)
	for c := li.FirstChild; c != nil; c = c.NextSibling {
		renderMarkdown(b, c, 0)
	}
	b.WriteString("\n")
}

func writePreText(b *strings.Builder, n *html.Node) {
	if n == nil {
		return
	}
	if n.Type == html.TextNode {
		b.WriteString(html.UnescapeString(n.Data))
		return
	}
	for c := n.FirstChild; c != nil; c = c.NextSibling {
		writePreText(b, c)
	}
}

func getAttr(n *html.Node, name string) string {
	for _, a := range n.Attr {
		if a.Key == name {
			return a.Val
		}
	}
	return ""
}

var whitespacePattern = regexp.MustCompile(`\s+`)

func collapseWhitespace(s string) string {
	if s == "" {
		return ""
	}
	return whitespacePattern.ReplaceAllString(s, " ")
}

func collapseBlankLines(s string) string {
	for strings.Contains(s, "\n\n\n") {
		s = strings.ReplaceAll(s, "\n\n\n", "\n\n")
	}
	return s
}
