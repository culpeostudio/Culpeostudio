// Package localinference describes the requests, streamed responses and warm-up
// progress exchanged with a locally running model.
package localinference

import (
	"bufio"
	"bytes"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"strings"
)

func ReadOpenAIStream(r io.Reader, emit func(string) error) (string, error) {
	reader := bufio.NewReader(r)
	var reply strings.Builder
	var eventData bytes.Buffer
	flushEvent := func() (bool, error) {
		raw := bytes.TrimSpace(eventData.Bytes())
		eventData.Reset()
		if len(raw) == 0 {
			return false, nil
		}
		if bytes.Equal(raw, []byte("[DONE]")) {
			return true, nil
		}
		chunk := extractOpenAIChunk(raw)
		if chunk == "" {
			return false, nil
		}
		reply.WriteString(chunk)
		if emit != nil {
			if err := emit(chunk); err != nil {
				return false, err
			}
		}
		return false, nil
	}

	for {
		line, err := reader.ReadBytes('\n')
		if len(line) > 0 {
			trimmed := bytes.TrimSpace(bytes.TrimRight(line, "\r\n"))
			switch {
			case len(trimmed) == 0:
				done, flushErr := flushEvent()
				if flushErr != nil {
					return "", flushErr
				}
				if done {
					return finishReply(reply.String())
				}
			case bytes.HasPrefix(trimmed, []byte("data:")):
				data := bytes.TrimSpace(bytes.TrimPrefix(trimmed, []byte("data:")))
				if len(data) > 0 {
					if eventData.Len() > 0 {
						eventData.WriteByte('\n')
					}
					eventData.Write(data)
				}
			}
		}
		if err != nil {
			if errors.Is(err, io.EOF) {
				_, flushErr := flushEvent()
				if flushErr != nil {
					return "", flushErr
				}
				return finishReply(reply.String())
			}
			return "", err
		}
	}
}

func finishReply(reply string) (string, error) {
	if strings.TrimSpace(reply) == "" {
		return "", fmt.Errorf("lokales Modell hat keine Chat-Antwort geliefert")
	}
	return reply, nil
}

func extractOpenAIChunk(raw []byte) string {
	var payload struct {
		Choices []struct {
			Delta struct {
				Content string `json:"content"`
			} `json:"delta"`
			Message struct {
				Content string `json:"content"`
			} `json:"message"`
			Text string `json:"text"`
		} `json:"choices"`
	}
	if err := json.Unmarshal(raw, &payload); err != nil {
		return ""
	}
	var out strings.Builder
	for _, choice := range payload.Choices {
		out.WriteString(choice.Delta.Content)
		out.WriteString(choice.Message.Content)
		out.WriteString(choice.Text)
	}
	return out.String()
}
