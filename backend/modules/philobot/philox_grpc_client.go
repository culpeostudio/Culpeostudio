package philobot

import (
	"context"
	"errors"
	"fmt"
	"io"
	"strings"
	"sync"
	"time"

	pb "github.com/fillyengine/backend/proto"
	"github.com/gofiber/fiber/v2"
	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
)

type PhiloxGRPCClient struct {
	address string
	timeout time.Duration

	mu     sync.Mutex
	conn   *grpc.ClientConn
	client pb.PhiloxAgenticServiceClient
}

type agenticStreamRequest struct {
	SessionID    string
	Message      string
	Mode         string
	AllowedRoots []string
	Context      map[string]string
}

func NewPhiloxGRPCClient(address string, timeout time.Duration) *PhiloxGRPCClient {
	return &PhiloxGRPCClient{address: strings.TrimSpace(address), timeout: timeout}
}

func (c *PhiloxGRPCClient) Connect() error {
	c.mu.Lock()
	defer c.mu.Unlock()
	if c.client != nil {
		return nil
	}
	if c.address == "" {
		return fmt.Errorf("Philox gRPC Adresse fehlt")
	}
	conn, err := grpc.Dial(c.address, grpc.WithTransportCredentials(insecure.NewCredentials()))
	if err != nil {
		return err
	}
	c.conn = conn
	c.client = pb.NewPhiloxAgenticServiceClient(conn)
	return nil
}

func (c *PhiloxGRPCClient) Close() error {
	c.mu.Lock()
	defer c.mu.Unlock()
	if c.conn == nil {
		return nil
	}
	err := c.conn.Close()
	c.conn = nil
	c.client = nil
	return err
}

func (c *PhiloxGRPCClient) StreamAgentic(ctx context.Context, req agenticStreamRequest, emit func(string, interface{}) error) (string, error) {
	if err := c.Connect(); err != nil {
		return "", err
	}
	c.mu.Lock()
	client := c.client
	c.mu.Unlock()
	if client == nil {
		return "", fmt.Errorf("Philox gRPC Client ist nicht verbunden")
	}
	if c.timeout > 0 {
		var cancel context.CancelFunc
		ctx, cancel = context.WithTimeout(ctx, c.timeout)
		defer cancel()
	}

	protoReq := &pb.AgenticRequest{
		SessionId:     strings.TrimSpace(req.SessionID),
		UserMessage:   strings.TrimSpace(req.Message),
		ThinkingLevel: "agentic",
		Mode:          strings.TrimSpace(req.Mode),
		AllowedRoots:  append([]string{}, req.AllowedRoots...),
		Context:       req.Context,
	}
	if protoReq.Mode == "" {
		protoReq.Mode = "execute"
	}

	var stream interface {
		Recv() (*pb.AgenticResponse, error)
	}
	var err error
	if protoReq.Mode == "planning" {
		stream, err = client.PlanAgentic(ctx, protoReq)
	} else {
		stream, err = client.ExecuteAgentic(ctx, protoReq)
	}
	if err != nil {
		return "", err
	}

	var reply strings.Builder
	for {
		event, err := stream.Recv()
		if err == io.EOF {
			break
		}
		if err != nil {
			return reply.String(), err
		}
		eventType, data := protoAgenticResponseToSSE(event)
		if event.GetType() == pb.AgenticResponse_TEXT_DELTA {
			reply.WriteString(event.GetText())
		}
		if event.GetType() == pb.AgenticResponse_DONE && strings.TrimSpace(event.GetText()) != "" {
			reply.Reset()
			reply.WriteString(event.GetText())
		}
		if emit != nil && eventType != "" {
			if err := emit(eventType, data); err != nil {
				return reply.String(), err
			}
		}
		if event.GetType() == pb.AgenticResponse_ERROR {
			return reply.String(), errors.New(event.GetError())
		}
	}
	return reply.String(), nil
}

func protoAgenticResponseToSSE(resp *pb.AgenticResponse) (string, interface{}) {
	if resp == nil {
		return "", nil
	}
	switch resp.GetType() {
	case pb.AgenticResponse_TEXT_DELTA:
		return "text_delta", fiber.Map{"chunk": resp.GetText()}
	case pb.AgenticResponse_TOOL_START:
		return "tool_start", toolCallToMap(resp.GetToolCall())
	case pb.AgenticResponse_TOOL_RESULT:
		return "tool_result", toolCallToMap(resp.GetToolCall())
	case pb.AgenticResponse_PLANNING_QUESTIONS:
		return "planning_questions", fiber.Map{"planning": planningToMap(resp.GetPlanning())}
	case pb.AgenticResponse_PLAN_READY:
		return "plan_ready", fiber.Map{"planning": planningToMap(resp.GetPlanning())}
	case pb.AgenticResponse_APPROVAL_NEEDED:
		return "approval_needed", fiber.Map{"planning": planningToMap(resp.GetPlanning())}
	case pb.AgenticResponse_COMPRESSION_EVENT:
		return "compression", compressionToMap(resp.GetCompression())
	case pb.AgenticResponse_ERROR:
		return "error", fiber.Map{"message": resp.GetError()}
	case pb.AgenticResponse_DONE:
		return "done", fiber.Map{"reply": resp.GetText(), "done": resp.GetDone(), "planning": planningToMap(resp.GetPlanning())}
	default:
		return "", nil
	}
}

func toolCallToMap(call *pb.ToolCall) fiber.Map {
	if call == nil {
		return fiber.Map{}
	}
	return fiber.Map{
		"id":             call.GetId(),
		"name":           call.GetName(),
		"arguments":      call.GetArguments(),
		"result_preview": call.GetResultPreview(),
		"success":        call.GetSuccess(),
		"error":          call.GetError(),
	}
}

func planningToMap(state *pb.PlanningState) fiber.Map {
	if state == nil {
		return fiber.Map{}
	}
	questions := make([]fiber.Map, 0, len(state.GetQuestions()))
	for _, question := range state.GetQuestions() {
		options := make([]fiber.Map, 0, len(question.GetOptions()))
		for _, option := range question.GetOptions() {
			options = append(options, fiber.Map{
				"id":          option.GetId(),
				"label":       option.GetLabel(),
				"description": option.GetDescription(),
			})
		}
		questions = append(questions, fiber.Map{
			"id":           question.GetId(),
			"prompt":       question.GetPrompt(),
			"options":      options,
			"allow_custom": question.GetAllowCustom(),
		})
	}
	return fiber.Map{
		"status":       state.GetStatus(),
		"questions":    questions,
		"plan_summary": state.GetPlanSummary(),
		"steps":        append([]string{}, state.GetSteps()...),
		"risks":        append([]string{}, state.GetRisks()...),
		"tests":        append([]string{}, state.GetTests()...),
	}
}

func compressionToMap(event *pb.CompressionEvent) fiber.Map {
	if event == nil {
		return fiber.Map{}
	}
	return fiber.Map{
		"triggered":           event.GetTriggered(),
		"usage_before":        event.GetUsageBefore(),
		"usage_after":         event.GetUsageAfter(),
		"compressed_messages": event.GetCompressedMessages(),
		"memory_id":           event.GetMemoryId(),
	}
}

func agenticContext(bot BotConfig, approvePlan bool) map[string]string {
	context := map[string]string{}
	if strings.TrimSpace(bot.ID) != "" {
		context["bot_id"] = bot.ID
	}
	if strings.TrimSpace(bot.Name) != "" {
		context["bot_name"] = bot.Name
	}
	if strings.TrimSpace(bot.SystemPrompt) != "" {
		context["system_prompt"] = bot.SystemPrompt
	}
	if approvePlan {
		context["approve_plan"] = "true"
	}
	return context
}
