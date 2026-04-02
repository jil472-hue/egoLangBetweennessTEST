#' Compute ego language betweenness for all egos in a dataset
#'
#' This function builds an egor object from cleaned ego, alter, and edge
#' tables, converts each ego network to an igraph object, and computes
#' ego language betweenness for every ego using
#' `ego_language_betweenness_single()`.
#'
#' @param ego_df A data frame containing ego-level data.
#' @param alter_df A data frame containing alter-level data.
#' @param edge_df A data frame containing edge-level data.
#' @param ego_id_col Column name in `ego_df` containing ego IDs.
#' @param alter_id_col Column name in `alter_df` containing alter IDs.
#' @param source_col Column name in `edge_df` containing source alter IDs.
#' @param target_col Column name in `edge_df` containing target alter IDs.
#' @param ego_name Name of the ego node in the igraph object. Default is "ego".
#' @param community_attr Vertex attribute indicating language community.
#'   Default is "languageUsedCategory".
#' @param participant_col Optional column in `ego_df` to merge into output.
#'   Default is "participant".
#'
#' @return A data frame with one row per ego and a language betweenness score.
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
      community_attr = community_attr
    )

    out <- data.frame(
      ego_id = gr$.egoID,
      language_betweenness = score,
      stringsAsFactors = FALSE
    )

    out
  })

  results_df <- do.call(rbind, results)

  if (participant_col %in% names(ego_df)) {
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
