#' Subset Genes
#'
#' This will select genes based on minimum expression, coefficient of variation,
#' or by a preliminary PCA.
#'
#' @param input the input ex_sc.
#' @param threshold UMI threshold for gene detection
#' @param minCells number of cells expressed above threshold for a given gene
#' @param method can either be "Expression", CV", or "PCA".
#' @param nComp if method = PCA, the number of components to keep
#' @param cutoff the percentile of genes to keep

#' @export
#' @details
#' Genes will be first filtered by minimum expression selecting by subsetting to genes that are
#' expressed above the threshold in more than minCells.
#' If the method is CV, it will first subset the genes based on the expression cutoffs,
#' then find the coefficient of variation across all genes.
#' Next it will select the percentile of genes (cutoff) based on their coefficient of variation. The last method will perform PCA on the cells, and then look at the loadings of each gene. By finding genes that are off center (via malhanoobis distance) we can filter to include only genes that contribute significant variance to the data.
#' @examples
#' gene_subset <- subset_genes(input = exprs(ex_sc_example), method = "PCA", threshold = 3, minCells = 30, nComp = 15, cutoff = 0.75)

subset_genes <- function(input, method, threshold = 1, minCells = 10, nComp = 10, cutoff = 0.85, log = F){
  input <- exprs(input)
  gCount <- apply(input,1,function(x) length(which(x>=threshold))) # a bit wasteful if threshold = 0, but alas.
  gene_subset <- rownames(input[(which(gCount >= minCells)),])
  if(method =="Expression"){
    gene_subset <- gene_subset
  }
  if(method == "CV"){
    if(log){
      input <- log2(input[gene_subset,]+2)-1
    }
    g_exp <- input[gene_subset,]
    gsd <- apply(g_exp,1,sd)
    CV = sqrt((exp(gsd))^2-1)
    CV <- CV[order(CV)]
    gene_subset <- names(CV[round(length(CV)*cutoff):length(CV)])
  }
  if(method == "PCA"){
    if(log){
      input <- log2(input[gene_subset,]+2)-1
    }
    input_scale <- scale(input[gene_subset,])
    pc <- irlba::prcomp_irlba(t(input_scale), nComp, center = F)
    rownames(pc$rotation) <- gene_subset
    d <- mahalanobis(pc$rotation[,1:nComp], center=rep(0, nComp), cov = cov(pc$rotation[,1:nComp]))
    dThresh <- quantile(d,cutoff)
    gene_subset <- names(which(d>dThresh))
  }
  return(gene_subset)
}



