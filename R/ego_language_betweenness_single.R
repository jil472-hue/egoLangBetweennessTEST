#' Compute ego language betweenness in a single ego network
#'
#' Computes how often the ego lies on shortest paths between alters
#' belonging to different language communities.
#'
#' @param gr An igraph object representing a single ego network.
#' @param ego_name Name of the ego node. Default is "ego".
#' @param community_attr Vertex attribute indicating alter language community.
#' @param unknown_community Label assigned when alter community is missing.
#' @param mode Mode passed to igraph::all_shortest_paths().
#'
#' @return Numeric value representing ego language betweenness.
#' @export
ego_language_betweenness_single <- function(
    gr,
    ego_name = "ego",
    community_attr = "languageUsedCategory",
    unknown_community = "Unknown",
    mode = "all"
) {

  if (!inherits(gr, "igraph")) {
    stop("`gr` must be an igraph object.")
  }

  vertex_names <- igraph::V(gr)$name
  if (is.null(vertex_names)) {
    stop("Graph vertices must have a `name` attribute.")
  }

  ego_index <- which(vertex_names == ego_name)

  if (length(ego_index) == 0) {
    stop("Ego node not found in graph.")
  }

  if (length(ego_index) > 1) {
    stop("Multiple ego nodes found. `ego_name` must uniquely identify one node.")
  }

  community <- igraph::vertex_attr(gr, community_attr)

  if (is.null(community)) {
    community <- rep(unknown_community, igraph::vcount(gr))
  } else {
    community[is.na(community)] <- unknown_community
  }

  # ego does not belong to an alter community for this measure
  community[ego_index] <- NA_character_

  igraph::V(gr)$community_tmp__ <- community
  on.exit(igraph::delete_vertex_attr(gr, "community_tmp__"), add = TRUE)

  ego_bridge_betweenness <- 0

  # only consider alter–alter pairs
  alter_ids <- setdiff(seq_len(igraph::vcount(gr)), ego_index)

  if (length(alter_ids) < 2) {
    return(0)
  }

  node_pairs <- utils::combn(alter_ids, 2)

  for (pair_idx in seq_len(ncol(node_pairs))) {

    start_node <- node_pairs[1, pair_idx]
    end_node   <- node_pairs[2, pair_idx]

    start_community <- igraph::V(gr)$community_tmp__[start_node]
    end_community   <- igraph::V(gr)$community_tmp__[end_node]

    # skip pairs with missing/unknown community
    if (is.na(start_community) ||
        is.na(end_community) ||
        start_community == unknown_community ||
        end_community == unknown_community) {
      next
    }

    # only consider cross-community alter pairs
    if (!isTRUE(start_community == end_community)) {

      paths <- igraph::all_shortest_paths(
        gr,
        from = start_node,
        to = end_node,
        mode = mode
      )$res

      if (length(paths) > 0) {
        n_paths <- length(paths)

        for (path in paths) {
          path_names <- igraph::V(gr)$name[path]
          ego_pos <- match(ego_name, path_names)

          if (!is.na(ego_pos) &&
              ego_pos > 1 &&
              ego_pos < length(path_names)) {
            ego_bridge_betweenness <- ego_bridge_betweenness + (1 / n_paths)
          }
        }
      }
    }
  }

  ego_bridge_betweenness
}
