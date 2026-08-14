package engine

import (
	"context"
	"log"
	"sync"
	"time"

	"google.golang.org/protobuf/proto"

	enginev1 "github.com/culpeohq/backend/gen/go/culpeostudio/engine/v1"
	"github.com/culpeohq/backend/modules/node"
)

// nodeWatchInterval is how often the nodes are asked what they are running
// while somebody is watching the engine feed.
//
// A node has no way to push into this Studio's event hub: the tunnel is dialed
// from here, and a node that opened a stream back would be a second connection
// to keep alive for the sake of a list that changes every few minutes. Polling
// while a screen is open costs one small call per node and stops the moment
// the last subscriber leaves.
const nodeWatchInterval = 5 * time.Second

// watchNodeInstances keeps the engine feed honest about the machines that are
// not this one.
//
// Without it a node's instances would appear once and then vanish: the feed
// opens with a snapshot, the client replaces its list with it, and every
// change after that arrives as an event. An instance nobody publishes events
// for is an instance the client forgets.
func (m *EngineModule) watchNodeInstances() {
	ticker := time.NewTicker(nodeWatchInterval)
	defer ticker.Stop()

	// The last shape each node instance was published in, so an unchanged
	// instance does not produce an event every five seconds.
	lastSeen := map[string]*enginev1.EngineInstance{}

	for {
		select {
		case <-m.maintenanceStop:
			return
		case <-ticker.C:
			if m.events.subscriberCount() == 0 || len(m.nodeTargets()) == 0 {
				// Nobody is looking, or there is nothing to look at. Anything
				// remembered would be stale by the time it mattered again.
				if len(lastSeen) > 0 {
					lastSeen = map[string]*enginev1.EngineInstance{}
				}
				continue
			}
			m.publishNodeInstanceChanges(lastSeen)
		}
	}
}

// publishNodeInstanceChanges diffs one round of polling against the last and
// publishes what moved. lastSeen is updated in place.
func (m *EngineModule) publishNodeInstanceChanges(lastSeen map[string]*enginev1.EngineInstance) {
	ctx, cancel := context.WithTimeout(context.Background(), nodeListTimeout)
	defer cancel()

	instances, answered := m.pollNodeInstances(ctx)
	current := make(map[string]*enginev1.EngineInstance, len(instances))
	for _, instance := range instances {
		if instance == nil || instance.GetId() == "" {
			continue
		}
		current[instance.GetId()] = instance
	}

	for id, instance := range current {
		previous, known := lastSeen[id]
		if known && proto.Equal(previous, instance) {
			continue
		}
		lastSeen[id] = instance
		if known {
			m.events.publish("instance_changed", instance)
		} else {
			m.events.publish("instance_created", instance)
		}
	}
	for id := range lastSeen {
		if _, still := current[id]; still {
			continue
		}
		// A node that did not answer has not told us anything. Announcing its
		// instances as deleted would empty the list on every dropped tunnel,
		// and put it back on the next round.
		if !answered[node.NodeIDOf(id)] {
			continue
		}
		delete(lastSeen, id)
		m.events.publish("instance_deleted", map[string]interface{}{"id": id})
	}
}

// pollNodeInstances asks every enabled node what it is running and reports
// which of them answered.
//
// It is separate from nodeInstances because the difference between "this node
// runs nothing" and "this node said nothing" only matters here, where it
// decides whether an instance is announced as gone.
func (m *EngineModule) pollNodeInstances(ctx context.Context) ([]*enginev1.EngineInstance, map[string]bool) {
	targets := m.nodeTargets()
	if len(targets) == 0 {
		return nil, nil
	}
	results := make([][]*enginev1.EngineInstance, len(targets))
	reached := make([]bool, len(targets))

	var waiting sync.WaitGroup
	for index, target := range targets {
		_, client, err := m.nodeEngine(target.ID)
		if err != nil {
			continue
		}
		waiting.Add(1)
		go func(index int, target node.Target, client enginev1.EngineServiceClient) {
			defer waiting.Done()
			callCtx, cancel := context.WithTimeout(ctx, nodeListTimeout)
			defer cancel()
			response, callErr := client.ListInstances(callCtx, &enginev1.ListInstancesRequest{})
			if callErr != nil {
				log.Printf("[engine] Instanzen von Node %s: %v", target.Name, callErr)
				return
			}
			reached[index] = true
			instances := make([]*enginev1.EngineInstance, 0, len(response.GetInstances()))
			for _, instance := range response.GetInstances() {
				instances = append(instances, qualifyInstance(target, instance))
			}
			results[index] = instances
		}(index, target, client)
	}
	waiting.Wait()

	var collected []*enginev1.EngineInstance
	answered := make(map[string]bool, len(targets))
	for index, target := range targets {
		collected = append(collected, results[index]...)
		if reached[index] {
			answered[target.ID] = true
		}
	}
	return collected, answered
}
