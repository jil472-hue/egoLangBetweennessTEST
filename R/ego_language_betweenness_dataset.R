#' Compute ego language betweenness for all egos in a dataset
#'
#' This function builds an egor object from cleaned ego, alter, and edge
#' tables, converts each ego network to an igraph object, and computes
#' ego language betweenness for every ego using
#' `ego_language_betweenness_single()`.
#'
#' Betweenness is computed as the extent to which the ego lies on shortest
#' paths between alters belonging to different language communities,
#' considering only alter pairs with non-missing community assignments.
#'
#' In addition to the raw betweenness score, the function also returns the
#' number of valid alter pairs used in the calculation and a normalized
#' betweenness score, defined as raw betweenness divided by the number of
#' valid cross-community alter pairs.
#'
#' @param ego_df A data frame containing ego-level data.
#' @param alter_df A data frame containing alter-level data.
#' @param edge_df A data frame containing edge-level data.
#' @param ego_id_col Column name in `ego_df` containing ego IDs.
#' @param alter_id_col Column name in `alter_df` containing alter IDs.
#' @param source_col Column name in `edge_df` containing source alter IDs.
#' @param target_col Column name in `edge_df` containing target alter IDs.
#' @param ego_name Name of the ego node in the igraph object. Default is "ego".
#' @param community_attr Vertex attribute indicating alter language community.
#'   Default is "languageUsedCategory".
#' @param unknown_community Label used for missing alter language community.
#'   Default is "Unknown".
#' @param participant_col Optional column in `ego_df` to merge into output.
#'   Default is "participant".
#'
#' @return A data frame with one row per ego containing the raw language
#'   betweenness score, the number of valid alter pairs, and the normalized
#'   betweenness score.
#' @export
ego_language_betweenness_dataset <- function(
    ego_df,
    alter_df,
    edge_df,
    ego_id_col = "networkCanvasEgoUUID",
    alter_id_col = "networkCanvasUUID",
    source_col = "networkCanvasSourceUUID",
    target_col = "networkCanvasTargetUUID",
    ego_name = "ego",
    community_attr = "languageUsedCategory",
    unknown_community = "Unknown",
    participant_col = "participant"
) {
  required_ego <- ego_id_col
  required_alter <- c(ego_id_col, alter_id_col, community_attr)
  required_edge <- c(ego_id_col, source_col, target_col)

  missing_ego <- setdiff(required_ego, names(ego_df))
  missing_alter <- setdiff(required_alter, names(alter_df))
  missing_edge <- setdiff(required_edge, names(edge_df))

  if (length(missing_ego) > 0) {
    stop("Missing required columns in `ego_df`: ",
         paste(missing_ego, collapse = ", "))
  }
  if (length(missing_alter) > 0) {
    stop("Missing required columns in `alter_df`: ",
         paste(missing_alter, collapse = ", "))
  }
  if (length(missing_edge) > 0) {
    stop("Missing required columns in `edge_df`: ",
         paste(missing_edge, collapse = ", "))
  }

  egor_obj <- egor::threefiles_to_egor(
    egos = ego_df,
    alters.df = alter_df,
    edges = edge_df,
    ID.vars = list(
      ego = ego_id_col,
      alter = alter_id_col,
      source = source_col,
      target = target_col
    )
  )

  gr_list <- egor::as_igraph(egor_obj, include.ego = TRUE)

  results <- lapply(seq_along(gr_list), function(i) {
    gr <- gr_list[[i]]

    score <- ego_language_betweenness_single(
      gr = gr,
      ego_name = ego_name,
      community_attr = community_attr,
      unknown_community = unknown_community
    )

    vertex_names <- igraph::V(gr)$name
    ego_index <- which(vertex_names == ego_name)

    if (length(ego_index) != 1) {
      stop("Each graph must contain exactly one ego node named `", ego_name, "`.")
    }

    community <- igraph::vertex_attr(gr, community_attr)

    if (is.null(community)) {
      community <- rep(unknown_community, igraph::vcount(gr))
    } else {
      community <- as.character(community)
      community[is.na(community)] <- unknown_community
    }

    alter_ids <- setdiff(seq_len(igraph::vcount(gr)), ego_index)

    n_valid_pairs <- 0

    if (length(alter_ids) >= 2) {
      node_pairs <- utils::combn(alter_ids, 2)

      for (pair_idx in seq_len(ncol(node_pairs))) {
        start_node <- node_pairs[1, pair_idx]
        end_node   <- node_pairs[2, pair_idx]

        start_community <- community[start_node]
        end_community   <- community[end_node]

        if (is.na(start_community) ||
            is.na(end_community) ||
            start_community == unknown_community ||
            end_community == unknown_community) {
          next
        }

        if (!isTRUE(start_community == end_community)) {
          n_valid_pairs <- n_valid_pairs + 1
        }
      }
    }

    score_norm <- if (n_valid_pairs > 0) score / n_valid_pairs else NA_real_

    data.frame(
      ego_id = gr$.egoID,
      language_betweenness = score,
      n_valid_pairs = n_valid_pairs,
      language_betweenness_norm = score_norm,
      stringsAsFactors = FALSE
    )
  })

  results_df <- do.call(rbind, results)

  if (!is.null(participant_col) && participant_col %in% names(ego_df)) {
    participant_df <- unique(ego_df[, c(ego_id_col, participant_col), drop = FALSE])
    names(participant_df) <- c("ego_id", "participant")

    results_df <- merge(
      results_df,
      participant_df,
      by = "ego_id",
      all.x = TRUE
    )
  }

  results_df
}
