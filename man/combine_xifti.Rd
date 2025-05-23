% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/combine_xifti.R
\name{combine_xifti}
\alias{combine_xifti}
\title{Combine \code{"xifti"}s with non-overlapping brain structures}
\usage{
combine_xifti(..., xii_list = NULL, meta = c("first", "all"))
}
\arguments{
\item{...}{The \code{"xifti"} objects}

\item{xii_list}{Alternatively, a list of \code{"xifti"} objects. If specified,
will ignore \code{...}}

\item{meta}{\code{"first"} (default) to just use the metadata from the first
argument, or \code{"all"} to include the other metadata in a list.}
}
\value{
A \code{"xifti"} with data from the inputs
}
\description{
Combine two to three \code{"xifti"}s with non-overlapping brain structures into
a single \code{"xifti"}. The names, intent, and surfaces of the first will be used,
if present. To add more surfaces to the result, use \code{\link{add_surf}}.
}
\seealso{
Other manipulating xifti: 
\code{\link{add_surf}()},
\code{\link{apply_parc}()},
\code{\link{apply_xifti}()},
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
\code{\link{smooth_cifti}()},
\code{\link{transform_xifti}()}
}
\concept{manipulating xifti}
