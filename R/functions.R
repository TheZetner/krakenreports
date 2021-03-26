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
    filter(taxid != 0, taxid != "A") %>%
    select(taxid) %>%
    unique() %>%
    rowwise(taxid) %>%
    mutate(taxeng = rentrez::entrez_fetch(db = "taxonomy", id = taxid, rettype = "text"),
           taxeng = stringr::str_match(taxeng, pattern = "1\\. (.*)\n"),
           taxeng = taxeng[,2]) %>%
    right_join(x, by = "taxid") %>%
    mutate(taxeng = replace_na(taxeng, "Unclassified")) %>%
    select(Status, SEQID, TAXID, Length, order, taxid, taxeng, kmers) %>%
    mutate(taxeng = case_when(
      taxid == "A" ~ "Ambiguous",
      TRUE ~ taxeng
    )) %>%
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
    filter(!is.na(CIGARstart))
}

#' Tidy Paired Kmer data in preparation to plot
#'
#' Grabs the NCBI taxa names and returns a tidied kmer tibble. Includes consideration for reads from paired data
#'
#' @param x kraken tsv file imported with read.delim
#' @return tibble of tidied kmer data: Status SEQID TAXID Length order taxid taxeng kmers read CIGARstart CIGARstart
#'
#' @import dplyr tibble tidyr forcats rentrez
#'
#' @export

tidyPairedKmerData <- function(x){
  x <- mapped %>%
    separate(Length, into = c("Length_1", "Length_2")) %>%
    separate(CIGAR, into = c("CIGAR_1", "CIGAR_2"), sep = " \\|\\:\\| " ) %>%
    pivot_longer(cols = Length_1:CIGAR_2, names_to = c("Set", "read"), names_pattern = "(.*)_(.*)") %>%
    pivot_wider(id_cols = c("Status", "SEQID", "TAXID", "Set", "read"), names_from = "Set", values_from = "value") %>%
    separate_rows(CIGAR, sep = " ") %>%
    group_by(SEQID, read) %>%
    mutate(order = row_number()) %>%
    separate(CIGAR, into = c("taxid", "kmers"), convert = T) %>%
    ungroup()

  x %>%
    filter(taxid != 0, taxid != "A") %>%
    select(taxid) %>%
    unique() %>%
    rowwise(taxid) %>%
    mutate(taxeng = rentrez::entrez_fetch(db = "taxonomy", id = taxid, rettype = "text"),
           taxeng = stringr::str_match(taxeng, pattern = "1\\. (.*)\n"),
           taxeng = taxeng[,2]) %>%
    right_join(x, by = "taxid") %>%
    mutate(taxeng = replace_na(taxeng, "Unclassified")) %>%
    select(Status, SEQID, TAXID, Length, order, taxid, taxeng, kmers, everything()) %>%
    mutate(taxeng = case_when(
      taxid == "A" ~ "Ambiguous",
      TRUE ~ taxeng
    )) %>%
    group_by(SEQID, read) %>%
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
               read = first(.$read, 1),
               CIGARPOS = 0)) %>% # Start at 0 so lag mutate will make first kmer pos 1
    arrange(SEQID, read, CIGARPOS) %>%
    mutate(CIGARPOS2 = lag(CIGARPOS) + 1) %>% # Plus 1 because so kmer positions don't overlap
    rename(CIGARstart = CIGARPOS2, CIGARend = CIGARPOS) %>%
    filter(!is.na(CIGARstart))
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
  p <- x %>%
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
  if("read" %in% names(x)){
    p + facet_grid(read ~ ., scales = "free", labeller = label_both)
  } else{
    p
  }
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


#' Plot Summary Ridges
#'
#' Create ridges plot that shows what proportion of kmers in all reads are assigned to each taxonomic group
#'
#' @param x tidied kmer cigar data from tidyKmerCigar
#' @return Ridges plots
#'
#' @export

plotSummary <- function(x){
  x %>%
    ungroup() %>%
    group_by(Status, SEQID, taxeng) %>%
    summarise(Count = sum(kmers)) %>%
    arrange(Status, SEQID, desc(Count)) %>%
    select(Status, Sequence = SEQID, TaxonomicName = taxeng, Count, everything()) %>%
    group_by(Status, Sequence) %>%
    mutate(Count = replace_na(Count, 0),
           kmers = sum(Count)) %>%
    mutate(prop = Count/kmers) %>%
    filter(!is.nan(prop)) %>%
    ungroup() %>%
    semi_join(., count(., TaxonomicName) %>% filter(n > 1), by = "TaxonomicName") %>%
    ggplot(aes(x = prop, y = fct_rev(TaxonomicName), fill = TaxonomicName)) +
    geom_density_ridges(alpha = 0.5, rel_min_height = 0) +
    labs(title = "Density of k-mer Proportion by Taxonomy for all Analyzed Reads",
         x = "Proportion of k-mers in Read Assigned to Taxonomic Name",
         y = "Taxonomic Name",
         fill = "Taxonomic Name") +
    theme(legend.position = "bottom",
          legend.direction = "vertical")

}
