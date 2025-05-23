% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/utils_surf.R
\name{boundary_mask_surf}
\alias{boundary_mask_surf}
\title{Boundary region of a mask}
\usage{
boundary_mask_surf(faces, mask, boundary_width = 10)
}
\arguments{
\item{faces}{An \eqn{F \times 3} matrix, where each row contains the vertex
indices for a given triangular face in the mesh. \eqn{F} is the number of
faces in the mesh.}

\item{mask}{A length \eqn{V} logical vector indicating if each vertex is
within the input mask.}

\item{boundary_width}{A positive integer representing the width of the
boundary to compute. The furthest vertices from the input mask will be this
number of edges away from the closest vertex in the input mask. Default:
\code{10}.}
}
\value{
A length-V logical vector. Each entry corresponds to the vertex
with the same index. The value is true if a vertex is within
\code{boundary_width} edges of a vertex in the mask, but is not within the
mask itself.
}
\description{
Identify the vertices within \code{boundary_width} edges of a vertex in the
input mask on a triangular mesh. Returns a logical indicating if a vertex
is within \code{boundary_width} edges of the mask.
}
\seealso{
Other surface-related: 
\code{\link{add_surf}()},
\code{\link{edit_mask_surf}()},
\code{\link{even_vert_samp}()},
\code{\link{is.surf}()},
\code{\link{load_surf}()},
\code{\link{mask_surf}()},
\code{\link{read_surf}()},
\code{\link{resample_surf}()},
\code{\link{rotate_surf}()},
\code{\link{surf_area}()},
\code{\link{view_surf}()},
\code{\link{write_surf_gifti}()}
}
\concept{surface-related}
