check_wb <- function() {
  if (is.null(ciftiTools.getOption("wb_path"))) {
    skip("Connectome Workbench is not available.")
  }
}

test_that("Miscellaneous functions are working", {
  check_wb()

  tdir <- tempdir()

  fnames <- ciftiTools.files()

  surfL_6k_fname <- file.path(tdir, "L_6k.surf.gii")
  resample_gifti(
    fnames$surf["left"], surfL_6k_fname,
    hemisphere="left", resamp_res=6000
  )
  surfR_6k_fname <- file.path(tdir, "R_6k.surf.gii")
  resample_gifti(
    fnames$surf["right"], surfR_6k_fname,
    hemisphere="right", resamp_res=6000
  )

  surfL_1k_fname <- file.path(tdir, "L_1k.surf.gii")
  resample_gifti(
    fnames$surf["left"], surfL_1k_fname,
    hemisphere="left", resamp_res=1000
  )
  surfR_1k_fname <- file.path(tdir, "R_1k.surf.gii")
  resample_gifti(
    fnames$surf["right"], surfR_1k_fname,
    hemisphere="right", resamp_res=1000
  )

  # List Options
  ciftiTools.listOptions()

  # Surface mask manipulation
  cii_fname <- fnames$cifti[1]
  cii <- read_cifti(cii_fname, brainstructures="left", surfL_fname="inflated", idx=1)
  cii <- cii > 1.5
  cii2 <- dilate_mask_surf(
    cii$data$cortex_left[,1],
    cii$meta$cortex$medial_wall_mask$left,
    cii$surf$cortex_left,
    hemisphere="left"
  )
  plot(cii+as.matrix(as.numeric(cii2))); rgl::close3d()
  cii2 <- edit_mask_surf(
    cii$data$cortex_left[,1],
    cii$meta$cortex$medial_wall_mask$left,
    cii$surf$cortex_left,
    hemisphere="left",
    depth=4
  )
  plot(cii+as.matrix(as.numeric(cii2)), zlim=c(0, 2)); rgl::close3d()
  plot(cii); rgl::close3d()
  plot(make_surf(
    mask_surf(
      cii$surf$cortex_left,
      move_from_mwall(cii)$data$cortex_left[,1]
    )
  )); rgl::close3d()

  for (cii_fname in fnames$cifti) {
    cat("\n\n"); cat(cii_fname); cat("\n\n")

    brainstructures <- info_cifti(cii_fname)$cifti$brainstructures

    surf_fnames <- switch(gsub(".nii", "", ciftiTools:::get_cifti_extn(cii_fname), fixed=TRUE),
      dscalar = list(left=surfL_6k_fname, right=surfR_6k_fname),
      dtseries = list(left=fnames$surf["left"], right=fnames$surf["right"]),
      dscalar_ones = list(left=surfL_1k_fname, right=surfR_1k_fname),
      dlabel = list(left=surfL_6k_fname, right=surfR_6k_fname)
    )

    # smooth_cifti
    # not sure why it doesn't work for ones_1k (because all data are equal?)
    if (!grepl("ones_1k", cii_fname) && !grepl("dlabel", cii_fname)) {
      testthat::expect_warning(cii <- read_cifti(
        smooth_cifti(
          cii_fname, file.path(tdir, basename(cii_fname)),
          surf_FWHM=3, vol_FWHM=3,
          surfL_fname=surf_fnames$left,
          surfR_fname=surf_fnames$right,
          subcortical_zeroes_as_NA=TRUE
        ),
        brainstructures = "all" #warning should happen if not all are present
      ))
      cii <- smooth_cifti(
        cii, file.path(tdir, basename(cii_fname)),
        surf_FWHM=5, vol_FWHM=5,
        surfL_fname=surf_fnames$left,
        surfR_fname=surf_fnames$right,
        subcortical_zeroes_as_NA=TRUE
      )
      cii <- smooth_cifti(
        cii, file.path(tdir, basename(cii_fname)),
        surf_FWHM=7, vol_FWHM=7
      )
    }

    cii <- read_cifti(cii_fname, brainstructures = brainstructures)
    if (!is.null(cii$meta$cortex$medial_wall_mask$left)) {
      cii <- add_surf(cii, surfL=resample_surf(surf_fnames$left, resamp_res=length(cii$meta$cortex$medial_wall_mask$left)))
    }

    cii_s <- convert_xifti(cii, "dscalar")
    cii_t <- convert_xifti(cii, "dtseries")
    if (!grepl("ones", cii_fname)) {
      cii_l <- convert_xifti(cii, "dlabel", nsig=2)
      cii_l1 <- select_xifti(cii, 1)
      cii_l1$data$cortex_left[1,] <- NA; cii_l1$data$cortex_left[seq(2, 100),] <- NaN
      cii_l1 <- convert_xifti(cii_l1, "dlabel", nsig=1, colors=c("grey", "blue"), add_white=FALSE)
      cii_l1 <- read_xifti(convert_xifti(cii_fname, "dlabel", file.path(tdir, "cii.dlabel.nii"), nsig=3), brainstructures = brainstructures)
    } else {
      cii$data$cortex_left[seq(5),] <- seq(5)
      cii_l <- convert_to_dlabel(cii, return_conversion_table = TRUE)
      cii_l <- convert_to_dlabel(
        cii_l$xifti,
        levels_old=c(0, 4, 3, 2, 1),
        levels = c(99, 1, 1, 1, 1),
        labels=c("a", "w", "x", "y", "z"),
        return_conversion_table = TRUE
      )
      testthat::expect_equal(sum(c(as.matrix(cii_l$xifti))==99), 33705)
      testthat::expect_equal(sum(c(as.matrix(cii_l$xifti))==1), 4)
      testthat::expect_equal(cii_l$xifti$meta$cifti$labels$ones$Key, c(1, 99))
      testthat::expect_equal(rownames(cii_l$xifti$meta$cifti$labels$ones), c("w", "a"))
      cii_l$xifti$data$cortex_left[seq(2),] <- c(NA, NaN)
      cii_l <- convert_to_dlabel(
        cii_l$xifti,
        levels = c(3, -1),
        colors=c("red", "blue"),
        add_white=FALSE,
        return_conversion_table = TRUE
      )
      testthat::expect_equal(cii_l$xifti$data$cortex_left[seq(2),], c(NA, NaN))
    }
    cii_s1 <- read_xifti(convert_xifti(cii_fname, "dscalar", file.path(tdir, "cii.dscalar.nii")), brainstructures = brainstructures)
    cii_t1 <- read_xifti(convert_xifti(cii_fname, "dtseries", file.path(tdir, "cii.dtseries.nii")), brainstructures = brainstructures)
    testthat::expect_equal(as.matrix(cii_s), as.matrix(cii_s1))
    testthat::expect_equal(as.matrix(cii_t), as.matrix(cii_t1))
    testthat::expect_equal(as.matrix(cii_s), as.matrix(cii_t))
    # testthat::expect_equal(as.matrix(cii_l), as.matrix(cii_l1)) # [TO DO]: off by one due to l1 having `???` key at 0

    # remove_xifti (not exported)
    cii <- ciftiTools:::remove_xifti(cii, c("cortex_left", "sub", "surf_right"))

    # move_*_mwall
    if (grepl("label", cii_fname)) {
      x <- cii$meta$cifti$labels[[1]][1,]
      cii2 <- move_to_mwall(cii, 0, TRUE)
      cii2 <- move_from_mwall(cii2, 0, rownames(x), x[,c("Red", "Green", "Blue", "Alpha")])
      cii3 <- move_to_mwall(cii, 1)
    } else {
      cii2 <- move_to_mwall(move_from_mwall(cii, NA), NA)
    }
    testthat::expect_equal(cii, cii2)

    # # fMRItools::unmask_mat
    # if (!is.null(cii$data$cortex_left)) {
    #   cor2 <- fMRItools::unmask_mat(
    #     cii$data$cortex_left,
    #     cii$meta$cortex$medial_wall_mask$left
    #   )
    # }
    # if (!is.null(cii$data$cortex_right)) {
    #   cor2 <- fMRItools::unmask_mat(
    #     cii$data$cortex_right,
    #     cii$meta$cortex$medial_wall_mask$right
    #   )
    # }

    # unvec_vol
    if (!is.null(cii$data$subcort)) {
      vol2 <- unvec_vol(cii$data$subcort, cii$meta$subcort$mask)
      labs2 <- unvec_vol(
        as.numeric(cii$meta$subcort$labels),
        cii$meta$subcort$mask
      )
      sub2 <- ciftiTools:::make_subcort(vol2, labs2)
      #sub2 <- make_subcort(vol2, labs2, cii$meta$subcort$mask)
      testthat::expect_equal(sub2$data, cii$data$subcort)
      testthat::expect_equal(sub2$labels, cii$meta$subcort$labels)

      cii2 <- cii
      cii2$data$subcort[seq(3),] <- 0
      cii2 <- move_to_submask(cii2, 0)
      cii2 <- move_from_submask(cii$meta$subcort$mask)
    }

    # `impute_xifti`
    cii <- read_cifti(cii_fname)
    #if (grepl("ones_1k", cii_fname)) { cii <- newdata_xifti(cii, seq(prod(dim(cii)))) }
    if (ncol(cii) < 2) { cii <- select_xifti(cii, c(1,1)) }
    cii <- add_surf(cii, "midthickness", "midthickness")
    cii_x <- cii
    cii_x$data$cortex_left[,2] <- ifelse(
      rnorm(nrow(cii_x$data$cortex_left)) > 0,
      NA, cii_x$data$cortex_left[,2]
    )
    cii_x$data$cortex_right[seq(floor(nrow(cii_x$data$cortex_right)/5)),] <- NA
    if (!is.null(cii_x$data$subcort)) {
      cii_x$data$subcort[,1] <- ifelse(
        rnorm(nrow(cii_x$data$subcort)) > 1,
        NA, cii_x$data$subcort[,1]
      )
    }
    cii_i <- impute_xifti(cii_x, impute_FUN = length)
    z <- merge_xifti(select_xifti(cii_x, 2), select_xifti(cii_i, 2))
    plt <- plot(
      z, idx=seq(2), together="idx", widget=FALSE,
      fname=file.path(tempdir(), "x.png"),
      material=list(lit=FALSE, smooth=FALSE), edge_color="black"
    )

    cii_xi <- select_xifti(cii, 2)
    cii_xi <- remove_xifti(cii_xi, "cortex_left")
    i_mask <- !(as.matrix(cii_xi) %in% c(min(cii_xi), max(cii_xi)))
    if (grepl("label", cii_fname)) {
      cii_i <- impute_xifti(cii_xi, function(x){x[which(!is.na(x))[1]]}, mask=i_mask)
    } else {
      cii_i <- impute_xifti(cii_xi, mask=i_mask)
      cii_xi <- newdata_xifti(cii_xi, ifelse(!i_mask, as.matrix(cii_xi), NA))
      cii_i2 <- impute_xifti(cii_xi)
      print(summary(cii_i2))
      testthat::expect_equal(max(cii_i- cii_i2), 0)
    }

    # Operations
    # warnings should happen for dlabel file
    if (grepl("label", cii_fname)) {
      is.xifti(testthat::expect_warning(cii + cii + cii))
      is.xifti(testthat::expect_warning(cii - cii / (abs(cii) + 1)))
      is.xifti(testthat::expect_warning((5*cii) %% round(cii, 1)))
      testthat::expect_equal(
        testthat::expect_warning((exp(1)^log(cii) + 0)$data),
        (cii*1)$data
      )
    } else {
      is.xifti(cii + cii + cii)
      is.xifti(cii - cii / (abs(cii) + 1))
      is.xifti((5*cii) %% round(cii, 1))
      testthat::expect_equal((exp(1)^log(cii) + 0)$data, (cii*1)$data)
    }

    # Select
    L <- ciftiTools:::ncol_xifti(cii)
    if (L > 1) {
      cii <- select_xifti(cii, seq(2,1))
      # Concat
      cii <- merge_xifti(xifti_list=list(merge_xifti(cii, cii), cii))
      testthat::expect_equal(
        select_xifti(cii, rep(seq(ciftiTools:::ncol_xifti(cii)), 2))$data,
        merge_xifti(cii, cii)$data
      )
    }

    # set_names_xifti
    if (grepl("label|scalar", cii_fname)) {
      cii1 <- set_names_xifti(cii, paste0("Column ", seq(ncol(cii))))
    }

    # combine_xifti
    cii1 <- combine_xifti(
      read_xifti(cii_fname, brainstructures="left"),
      read_xifti(cii_fname, brainstructures="right")
    )
    cii2 <- read_xifti(cii_fname, brainstructures=c("left", "right"))
    testthat::expect_equal(cii1, cii2)
    # [TO DO]: test with different intents; test expected errors

    cii2 <- newdata_xifti(cii2, as.matrix(cii2))
    stopifnot(max(abs(as.matrix(
      newdata_xifti(cii2, 17) - newdata_xifti(cii2, 10) - newdata_xifti(cii2, 7)
    ))) == 0)
    stopifnot(max(abs(as.matrix(
      newdata_xifti(cii2, 17) - 10
    ) - 7)) == 0)
    stopifnot(max(abs(as.matrix(
      newdata_xifti(cii2, 17) - matrix(10, nrow=nrow(as.matrix(cii2)), ncol=ncol(as.matrix(cii2))) - 7
    ))) == 0)


    if (!grepl("dlabel", cii_fname)) {
      # Smooth metric GIFTI
      fnames_sep <- separate_cifti(cii_fname, write_dir=tdir)
      smooth_gifti(fnames_sep[1], file.path(tdir, "sm.func.gii"), hemisphere="left")
      smg1 <- gifti::readgii(
        smooth_gifti(
          fnames_sep[3], file.path(tdir, "sm.func.gii"),
          ROI_fname=fnames_sep[4], hemisphere="right"
        )
      )
      smg2 <- gifti::readgii(separate_cifti(
        smooth_cifti(cii_fname, file.path(tdir, paste0("smooth.", basename(cii_fname)))),
        write_dir=tdir
      )[3])
      testthat::expect_equal(smg1$data$normal, smg2$data$normal)
    }

    # apply
    testthat::expect_equal(
      c(apply_xifti(cii1, 2, quantile, c(.1, .2, .5))),
      c(apply(cii1, 2, quantile, c(.1, .2, .5)))
    )

    cii2 <- select_xifti(cii2, idx=1)
    cii2$data$cortex_left <- as.vector(cii2$data$cortex_left)
    stopifnot(is.xifti(fix_xifti(cii2)))
  }

  scale_xifti(cii1, scale=FALSE)
  newdata_xifti(cii1, as.matrix(cii1)[,rep(seq(ncol(cii1)), 2)])

  # surf_area
  mySurf <- read_surf(ciftiTools.files()$surf["left"])
  surf_area_ours <- surf_area(mySurf)
  tfile <- tempfile(fileext=".func.gii")
  ciftiTools:::run_wb_cmd(paste(
    "-surface-vertex-areas",
    ciftiTools:::ciftiTools.files()$surf["left"],
    tfile
  ))
  surf_area_wb <- read_xifti2(tfile)$data$cortex_left[,]
  testthat::expect_lt(max(abs(surf_area_ours-surf_area_wb)), 1e-5)

  x <- read_cifti(fnames$cifti[1], surfL_fname=fnames$surf["left"], brainstructures="left")
  y <- read_cifti(fnames$cifti[2], surfR_fname=fnames$surf["right"], brainstructures="right")
  z <- combine_xifti(x,y)

  # parcellation matrix
  parc <- parc_add_subcortex(load_parc())
  z <- rowSums(ciftiTools:::parc_mean_mat(parc)>0)
  stopifnot(all(table(c(as.matrix(parc))) - z[!is.na(z)] == 0))

  # parcellation functions
  ### dummy data
  cii <- read_cifti(ciftiTools.files()$cifti["dscalar_ones"], resamp_res=32000)
  cii <- newdata_xifti(cii, cbind(as.matrix(cii), as.matrix(cii)+rnorm(prod(dim(cii)))))
  cii <- newdata_xifti(cii, cbind(as.matrix(cii), as.matrix(cii)+rnorm(prod(dim(cii)))))
  # tests
  q <- apply_parc(cii, parc)
  dim(parc_vals_to_xifti(parc, q))
  q <- cbind(q,q); colnames(q) <- c("a", "b")
  summary(parc_vals_to_xifti(parc, q))

  # unmask_subcortex
  q <- unmask_subcortex(cii)

  # More `impute_xifti` tests
  cii <- read_cifti(ciftiTools.files()$cifti["dscalar_ones"])
  cii <- add_surf(cii, surfL="inflated")
  my_vec <- c(0, rep(NA, 98), 1, NA, .1, NA, NA)
  cii$data$cortex_left[] <- rep(my_vec, 500)[seq(nrow(cii$data$cortex_left))]
  cii$data$subcort[] <- rep(my_vec, 5000)[seq(nrow(cii$data$subcort))]
  cii2 <- impute_xifti(cii)
  #plot(cii); plot(cii2)

  # `subcort_by_bs`
  cii <- read_cifti(ciftiTools.files()$cifti["dscalar_ones"])
  cii <- newdata_xifti(cii, seq(prod(dim(cii))))
  testthat::expect_equal(
    cii$data,
    newdata_xifti(cii, as.matrix(cii))$data
  )
  testthat::expect_equal(
    cii$data,
    newdata_xifti(cii, as.matrix(cii, subcortex_by_bs=TRUE), subcortex_by_bs=TRUE)$data
  )
})
