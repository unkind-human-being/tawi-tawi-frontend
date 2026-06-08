package com.rhyn.reach.data.repository.routing

import com.rhyn.reach.data.local.dao.MeshEdgeDao
import java.util.PriorityQueue
import javax.inject.Inject

class RoutePlanner @Inject constructor(private val meshEdgeDao: MeshEdgeDao) {

    suspend fun getShortestPath(startNodeId: String, targetNodeId: String): List<String>? {
        val allEdges = meshEdgeDao.getAllActiveEdges()
        val graph = mutableMapOf<String, MutableSet<String>>()

        // Two-Way Handshake Enforcement:
        // Only consider edges where A->B AND B->A exist.
        val edgeSet = allEdges.map { "${it.nodeA}->${it.nodeB}" }.toSet()

        allEdges.forEach { edge ->
            val reverseEdge = "${edge.nodeB}->${edge.nodeA}"
            if (edgeSet.contains(reverseEdge)) {
                graph.getOrPut(edge.nodeA) { mutableSetOf() }.add(edge.nodeB)
            }
        }

        // Dijkstra's Algorithm (Unweighted, utilizing PQ for future link-quality extension)
        val distances = mutableMapOf<String, Int>().withDefault { Int.MAX_VALUE }
        val previousNodes = mutableMapOf<String, String>()
        val queue = PriorityQueue<Pair<String, Int>>(compareBy { it.second })

        distances[startNodeId] = 0
        queue.add(Pair(startNodeId, 0))

        while (queue.isNotEmpty()) {
            val current = queue.poll() ?: continue
            val currentNode = current.first
            val currentDistance = current.second

            if (currentNode == targetNodeId) {
                // Reconstruct path
                val path = mutableListOf<String>()
                var curr: String? = targetNodeId
                while (curr != null) {
                    path.add(0, curr)
                    curr = previousNodes[curr]
                }
                // Return route EXCLUDING start and target nodes
                return if (path.size > 2) path.subList(1, path.size - 1) else emptyList()
            }

            if (currentDistance > distances.getValue(currentNode)) continue

            graph[currentNode]?.forEach { neighbor ->
                val newDist = currentDistance + 1
                if (newDist < distances.getValue(neighbor)) {
                    distances[neighbor] = newDist
                    previousNodes[neighbor] = currentNode
                    queue.add(Pair(neighbor, newDist))
                }
            }
        }
        return null // No known path exists
    }
}