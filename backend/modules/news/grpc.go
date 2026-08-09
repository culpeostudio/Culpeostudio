package news

import (
	"context"
	"errors"
	"log"
	"strings"
	"time"
	"unicode/utf8"

	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
	"google.golang.org/protobuf/types/known/timestamppb"

	newsv1 "github.com/culpeohq/backend/gen/go/culpeostudio/news/v1"
	"github.com/culpeohq/backend/internal/grpcmw"
)

type grpcService struct {
	newsv1.UnimplementedNewsServiceServer
	module *NewsModule
}

func (m *NewsModule) RegisterGRPC(server *grpc.Server) {
	newsv1.RegisterNewsServiceServer(server, &grpcService{module: m})
}

func (s *grpcService) ListNews(ctx context.Context, req *newsv1.ListNewsRequest) (*newsv1.ListNewsResponse, error) {
	s.module.mu.RLock()
	defer s.module.mu.RUnlock()

	items := make([]*newsv1.NewsItem, 0, len(s.module.items))
	for _, item := range s.module.items {
		items = append(items, newsItemToProto(item))
	}
	return &newsv1.ListNewsResponse{Items: items}, nil
}

func (s *grpcService) GetNews(ctx context.Context, req *newsv1.GetNewsRequest) (*newsv1.GetNewsResponse, error) {
	item, found := s.module.itemByID(req.GetId())
	if !found {
		return nil, status.Error(codes.NotFound, "News-Eintrag nicht gefunden")
	}
	return &newsv1.GetNewsResponse{Item: newsItemToProto(item)}, nil
}

func (s *grpcService) ListSavedArticles(ctx context.Context, req *newsv1.ListSavedArticlesRequest) (*newsv1.ListSavedArticlesResponse, error) {
	userID, err := authenticatedUserID(ctx)
	if err != nil {
		return nil, err
	}

	saved := s.module.saved.List(userID)
	articles := make([]*newsv1.SavedArticle, 0, len(saved))
	for _, article := range saved {
		articles = append(articles, savedArticleToProto(article))
	}
	return &newsv1.ListSavedArticlesResponse{Articles: articles}, nil
}

func (s *grpcService) SaveArticle(ctx context.Context, req *newsv1.SaveArticleRequest) (*newsv1.SaveArticleResponse, error) {
	userID, err := authenticatedUserID(ctx)
	if err != nil {
		return nil, err
	}

	item := newsItemFromProto(req.GetItem())
	// The cached copy wins, so a client cannot save a doctored article.
	if cached, found := s.module.itemByID(item.ID); found {
		item = cached
	}

	article, saveErr := s.module.saved.Save(userID, item, time.Now().UTC())
	if saveErr != nil {
		if errors.Is(saveErr, errSavedArticleIncomplete) {
			return nil, status.Error(codes.InvalidArgument, saveErr.Error())
		}
		log.Printf("[NEWS] Merkliste speichern fehlgeschlagen: %v", saveErr)
		return nil, status.Error(codes.Internal, "Beitrag konnte nicht gespeichert werden")
	}
	return &newsv1.SaveArticleResponse{Article: savedArticleToProto(article)}, nil
}

func (s *grpcService) DeleteSavedArticle(ctx context.Context, req *newsv1.DeleteSavedArticleRequest) (*newsv1.DeleteSavedArticleResponse, error) {
	userID, err := authenticatedUserID(ctx)
	if err != nil {
		return nil, err
	}

	removed, deleteErr := s.module.saved.Delete(userID, req.GetId())
	if deleteErr != nil {
		log.Printf("[NEWS] Merkliste loeschen fehlgeschlagen: %v", deleteErr)
		return nil, status.Error(codes.Internal, "Beitrag konnte nicht entfernt werden")
	}
	if !removed {
		return nil, status.Error(codes.NotFound, "Beitrag ist nicht gemerkt")
	}
	return &newsv1.DeleteSavedArticleResponse{}, nil
}

func authenticatedUserID(ctx context.Context) (string, error) {
	userID := strings.TrimSpace(grpcmw.UserIDFromContext(ctx))
	if userID == "" {
		return "", status.Error(codes.Unauthenticated, "Nicht autorisiert")
	}
	return userID, nil
}

func newsItemToProto(item NewsItem) *newsv1.NewsItem {
	message := &newsv1.NewsItem{
		Id:       item.ID,
		Title:    safeUTF8String(item.Title),
		Content:  safeUTF8String(item.Content),
		Author:   safeUTF8String(item.Author),
		Tags:     safeUTF8Strings(item.Tags),
		ImageUrl: safeUTF8String(item.ImageURL),
		Url:      safeUTF8String(item.URL),
		Category: safeUTF8String(item.Category),
	}
	if !item.PublishedAt.IsZero() {
		message.PublishedAt = timestamppb.New(item.PublishedAt)
	}
	return message
}

func safeUTF8String(s string) string {
	if utf8.ValidString(s) {
		return s
	}
	return strings.ToValidUTF8(s, "")
}

func safeUTF8Strings(values []string) []string {
	out := make([]string, len(values))
	for i, v := range values {
		out[i] = safeUTF8String(v)
	}
	return out
}

func newsItemFromProto(message *newsv1.NewsItem) NewsItem {
	if message == nil {
		return NewsItem{}
	}
	item := NewsItem{
		ID:       message.GetId(),
		Title:    message.GetTitle(),
		Content:  message.GetContent(),
		Author:   message.GetAuthor(),
		Tags:     append([]string{}, message.GetTags()...),
		ImageURL: message.GetImageUrl(),
		URL:      message.GetUrl(),
		Category: message.GetCategory(),
	}
	if published := message.GetPublishedAt(); published != nil {
		item.PublishedAt = published.AsTime()
	}
	return item
}

func savedArticleToProto(article SavedArticle) *newsv1.SavedArticle {
	message := &newsv1.SavedArticle{Item: newsItemToProto(article.NewsItem)}
	if !article.SavedAt.IsZero() {
		message.SavedAt = timestamppb.New(article.SavedAt)
	}
	return message
}
