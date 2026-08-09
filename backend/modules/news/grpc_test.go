package news

import (
	"testing"
	"time"

	newsv1 "github.com/culpeohq/backend/gen/go/culpeostudio/news/v1"
	"google.golang.org/protobuf/proto"
)

func TestNewsItemToProtoSanitizesInvalidUTF8(t *testing.T) {
	item := NewsItem{
		ID:          "feed-broken",
		Title:       "GPU \xff\xfe Technik",
		Content:     "Inhalt \x80\x81 kaputt",
		Author:      "Feed \xbd",
		Tags:        []string{"Hardware", "\xc3"},
		ImageURL:    "https://example.com/bild\xbf.png",
		URL:         "https://example.com/artikel-\xa0",
		Category:    "Hardware\xb1",
		PublishedAt: time.Now().UTC(),
	}

	message := newsItemToProto(item)
	wire, err := proto.Marshal(message)
	if err != nil {
		t.Fatalf("proto.Marshal() error = %v", err)
	}

	var decoded newsv1.NewsItem
	if err := proto.Unmarshal(wire, &decoded); err != nil {
		t.Fatalf("proto.Unmarshal() error = %v", err)
	}
	if decoded.GetTitle() != "GPU  Technik" {
		t.Fatalf("Title = %q, want sanitized %q", decoded.GetTitle(), "GPU  Technik")
	}
	if decoded.GetContent() != "Inhalt  kaputt" {
		t.Fatalf("Content = %q, want sanitized %q", decoded.GetContent(), "Inhalt  kaputt")
	}
	if decoded.GetAuthor() != "Feed " {
		t.Fatalf("Author = %q, want sanitized %q", decoded.GetAuthor(), "Feed ")
	}
	if decoded.GetTags()[0] != "Hardware" || decoded.GetTags()[1] != "" {
		t.Fatalf("Tags = %q, want first tag preserved and second cleaned", decoded.GetTags())
	}
	if decoded.GetImageUrl() != "https://example.com/bild.png" {
		t.Fatalf("ImageUrl = %q, want sanitized", decoded.GetImageUrl())
	}
	if decoded.GetUrl() != "https://example.com/artikel-" {
		t.Fatalf("Url = %q, want sanitized", decoded.GetUrl())
	}
	if decoded.GetCategory() != "Hardware" {
		t.Fatalf("Category = %q, want sanitized %q", decoded.GetCategory(), "Hardware")
	}
}

func TestNewsItemToProtoRoundTripValidUTF8(t *testing.T) {
	item := NewsItem{
		ID:          "hn-1",
		Title:       "Ägäis-Test mit Ümlauten",
		Content:     "Normaler Text ✓",
		Author:      "Hacker News",
		Tags:        []string{"HN"},
		PublishedAt: time.Now().UTC(),
	}

	message := newsItemToProto(item)
	wire, err := proto.Marshal(message)
	if err != nil {
		t.Fatalf("proto.Marshal() error = %v", err)
	}

	var decoded newsv1.NewsItem
	if err := proto.Unmarshal(wire, &decoded); err != nil {
		t.Fatalf("proto.Unmarshal() error = %v", err)
	}
	if decoded.GetTitle() != item.Title {
		t.Fatalf("Title = %q, want %q", decoded.GetTitle(), item.Title)
	}
	if decoded.GetContent() != item.Content {
		t.Fatalf("Content = %q, want %q", decoded.GetContent(), item.Content)
	}
}
