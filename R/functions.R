#' Read in Kmer data
#'
#' Returns a kmer tibble
#'
#' @param x path to kraken tsv
#' @return tibble of kmer data with columns "Status", "SEQID", "TAXID", "Length", "CIGAR"
#'
#' @import readr
#'
#' @export

readKmerData <- function(x){
  read_delim(x, "\t",
             escape_double = FALSE,
             trim_ws = TRUE,
             col_names = c("Status", "SEQID", "TAXID", "Length", "CIGAR"))
}


#' Tidy Kmer data in preparation to plot
#'
#' Grabs the NCBI taxa names and returns a tidied kmer tibble
#'
#' @param x kraken tsv file imported with read.delim
#' @return tibble of tidied kmer data: Status SEQID TAXID Length order taxid taxeng kmers CIGARstart CIGARstart
#'
#' @import dplyr tibble tidyr forcats rentrez
#'
#' @export

tidyKmerData <- function(x){
  x <- x %>%
    separate_rows(CIGAR, sep = " ") %>%
    group_by(SEQID) %>%
    mutate(order = row_number()) %>%
    separate(CIGAR, into = c("taxid", "kmers"), convert = T) %>%
    ungroup()

  x %>%
    filter(!(taxid %in% c(0, "A"))) %>%
    select(taxid) %>%
    unique() %>%
    rowwise(taxid) %>%
    mutate(taxeng = rentrez::entrez_fetch(db = "taxonomy", id = taxid, rettype = "text"),
           taxeng = stringr::str_match(taxeng, pattern = "1\\. (.*)\n"),
           taxeng = taxeng[,2]) %>%
    right_join(x, by = "taxid") %>%
    mutate(taxeng = replace_na(taxeng, "Unclassified")) %>%
    select(Status, SEQID, TAXID, Length, order, taxid, taxeng, kmers) %>%
    group_by(SEQID) %>%
    arrange(order) %>%
    mutate(CIGARPOS = cumsum(kmers)) %>%
    do(add_row(.,
               Status = first(.$Status, 1),
               SEQID = first(.$SEQID, 1),
               TAXID = first(.$TAXID, 1),
               Length = first(.$Length, 1),
               order = first(.$order, 1),
               taxid = first(.$taxid, 1),
               taxeng = first(.$taxeng, 1),
               kmers = first(.$kmers, 1),
               CIGARPOS = 0)) %>% # Start at 0 so lag mutate will make first kmer pos 1
    arrange(SEQID, CIGARPOS) %>%
    mutate(CIGARPOS2 = lag(CIGARPOS) + 1) %>% # Plus 1 because so kmer positions don't overlap
    rename(CIGARstart = CIGARPOS2, CIGARend = CIGARPOS) %>%
    filter(!is.na(CIGARstart)) %>%
    mutate(taxeng = case_when(
      taxid == "A" ~ "Ambiguous",
      TRUE ~ taxeng
    ))
}

#' Plot k-mer CIGAR
#'
#' Plot one sequence's CIGAR data
#'
#' @param x tidied kmer cigar data from cleanKmerData
#' @param seqid seqence id
#' @return Plot
#'
#' @import ggplot2 dplyr tibble tidyr forcats
#'
#' @export

plotKmerCigar <- function(x, seqid){
  x %>%
    mutate(taxlvl = as.numeric(as.factor(taxeng)),
           taxlvl2 = paste(taxlvl,". ", taxeng, sep = ""),
           taxlvl = as.factor(taxlvl)) %>%
    filter(SEQID == seqid) %>%
    ggplot(aes(y = taxlvl)) +
    geom_segment(aes(yend = taxlvl,
                     x = CIGARstart - 0.5,
                     xend = CIGARend + 0.5,
                     colour = taxlvl2),
                 size = 2,
                 show.legend = T) +
    theme(legend.title = element_blank(),
          legend.position='bottom') +
    scale_colour_viridis_d(begin = 0.2, direction = -1) +
    guides(colour=guide_legend(ncol=2)) +
    labs(x = "K-mer Position in Sequence",
         y = "Taxonomic Identification",
         title = seqid)
}

#' Plot All Kmer CIGARs
#'
#' Plot all Sequences from tidied kmer cigar table, facet by seqid, and colour by taxa
#'
#' @param x tidied kmer cigar data from tidyKmerCigar
#' @return List of Plots
#'
#' @export

plotAllKmerCigars <- function(x, lg = FALSE){
  if(n_distinct(x$SEQID) > 20 & lg == FALSE){return(message("Are you sure you want to create ", n_distinct(x$SEQID), " plots? Use argument lg=TRUE or filter your reads."))}
  p <- x %>%
    group_by(SEQID) %>%
    group_map(~ plotKmerCigar(.x, .y), .keep=T)
  p
}
