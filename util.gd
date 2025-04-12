extends Node

static func get_nearest_node2d(gpos: Vector2, nodes: Array[Node2D]) -> Node2D:
	if nodes.size() == 0:
		return null
	var min_node: Node2D = nodes[0]
	var min_dist_sqrd: float = INF

	for node: Node2D in nodes:
		var dist_srqd = gpos.distance_squared_to(node.global_position)
		if dist_srqd < min_dist_sqrd:
			min_dist_sqrd = dist_srqd
			min_node = node

	return min_node

static func remove_all_children(node: Node):
	for child in node.get_children():
		node.remove_child(child)
