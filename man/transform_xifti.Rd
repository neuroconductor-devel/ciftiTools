% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/transform_xifti.R
\name{transform_xifti}
\alias{transform_xifti}
\title{Apply a univariate transformation to a \code{"xifti"} or pair of \code{"xifti"}s.}
\usage{
transform_xifti(xifti, FUN, xifti2 = NULL, idx = NULL, ...)
}
\arguments{
\item{xifti}{A \code{"xifti"} object.}

\item{FUN}{The function. If \code{xifti2} is not provided, it should be
a univariate function like \code{log} or \code{sqrt}. If
\code{xifti2} is provided, it should take in two arguments, like \code{`+`}
or \code{pmax}.}

\item{xifti2}{The second xifti, if applicable. Otherwise, \code{NULL} (default)}

\item{idx}{The column indices for which to apply the transformation.
If \code{NULL} (default), apply to all columns. If two \code{"xifti"} objects,
were provided, the values in the first (\code{xifti}) will be retained for columns
that are not transformed.}

\item{...}{Additional arguments to \code{FUN}}
}
\value{
A \code{"xifti"} storing the result of applying \code{FUN} to the input(s).
The data dimensions will be the same. The metadata of \code{xifti} will be retained,
and the metadata of \code{xifti2} will be discarded (if provided).
}
\description{
Apply a univariate transformation to each value in a \code{"xifti"} or pair of
\code{"xifti"}s. If a pair, they must share the same dimensions (brainstructures)
and number of measurements.
}
\details{
If the \code{"xifti"} had the dlabel intent, and the transformation creates
any value that is not a label value (e.g. a non-integer), then it is converted
to a dscalar.

Technically, the function does not have to be univariate: it only has to return the
same number of values as the input. The function will be applied to the matrix
for each brain structure separately. For example, the function
\code{function(q){(q - mean(q)) / sd(q)}} will scale each brainstructure, while
\code{scale} will scale each column of each brainstructure.
}
\seealso{
Other manipulating xifti: 
\code{\link{add_surf}()},
\code{\link{apply_parc}()},
\code{\link{apply_xifti}()},
\code{\link{combine_xifti}()},
\code{\link{convert_xifti}()},
\code{\link{impute_xifti}()},
\code{\link{merge_xifti}()},
\code{\link{move_to_mwall}()},
\code{\link{move_to_submask}()},
\code{\link{newdata_xifti}()},
\code{\link{remap_cifti}()},
\code{\link{remove_xifti}()},
\code{\link{resample_cifti}()},
\code{\link{resample_cifti_from_template}()},
\code{\link{scale_xifti}()},
\code{\link{select_xifti}()},
\code{\link{set_names_xifti}()},
\code{\link{smooth_cifti}()}
}
\concept{manipulating xifti}
