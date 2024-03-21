code from previous projects

topup.m: creates blipup/blipdown fieldmaps using FSL's topup and matlab

run_conn.m: performs subject-level preprocessing and analysis using CONN

run_datacheck.m: creates a handy log of file names and amount of volumes per subject/task/session to check for data integrity

run_art.m: runs artifact detection tools for a bids-curated dataset and logs results

scale_hertz.m: scales a hz fieldmap to rads for use in spm12 preprocessing

dual_echo.m: combines two epi echoes to a single bold file

preproc_lesionfriendly.m: spm12 batch script that handles a cohort of mixed lesion/no lesion participants with available lesion masks

physio_preproc.m: processes physiologs for usage in bold-signal weighing for olfactory paradigms

run_physio.m: loops physio_preproc.m function across subjects and separates inhalation peaks into conditions
