      SUBROUTINE trcnxt
!!!---------------------------------------------------------------------
!!!
!!!                       ROUTINE trcnxt
!!!                     *******************
!!!
!!!  PURPOSE :
!!!  ---------
!!!    compute the passive tracers fields at the next time
!!!    step from their temporal trends
!!!
!!    METHOD :
!!
!!
!!      Apply lateral boundary conditions (nperio=0,closed  nperio=1,
!!      east-west cyclic nperio=2, symmetric round the equator)
!!      on tra arrays
!!
!!   default:
!!      arrays swap
!!         (trn) = (tra)   (tra) = (0,0)
!!         (trb) = (trn) 
!!
!!   For Arakawa Sheme : IF key_trc_arakawa defined
!!      A Asselin time filter applied on now tracers (trn) to avoid
!!      the divergence of two consecutive time-steps and tr arrays
!!      to prepare the next time_step:
!!         (trb) = (trn) + gamma [ (trb) + (tra) - 2 (trn) ]
!!         (trn) = (tra)   (tra) = (0,0)
!!
!!      array swap for tracers to start the next time step
!!
!!
!!      macrotasking on tracer slab
!!
!!
!!   INPUT :
!!   -----
!!
!!   OUTPUT :
!!   ------
!!      argument                : no
!!
!!   WORKSPACE :
!!   ---------
!!     ji jj jk jn zfact zdt


       USE myalloc
       USE myalloc_mpp
       USE FN_mem
       USE Time_Manager

      IMPLICIT NONE

!! local declarations
!! ==================
      INTEGER pack_size
! omp variables
      INTEGER :: mytid, ntids


#ifdef __OPENMP1
      INTEGER ::  omp_get_thread_num, omp_get_num_threads, omp_get_max_threads
      EXTERNAL :: omp_get_thread_num, omp_get_num_threads, omp_get_max_threads
#endif

      INTEGER ji,jj,jk,jn,jp


#ifdef __OPENMP1
      ntids = omp_get_max_threads() ! take the number of threads
      mytid = -1000000
#else
      ntids = mpi_pack_size
      mytid = 0
#endif


       trcnxtparttime = MPI_WTIME() ! cronometer-start

!! 1. fields at the next time
!! --------------------------
!! Tracer slab
!! ===========


      TRACER_LOOP: DO  jn = 1, jptra, ntids


!! 1. Lateral boundary conditions on tra (1,1,1,jn)

#ifdef key_mpp

!!   ... Mpp : export boundary values to neighboring processors

        IF( ntids - 1 + jn <= jptra ) THEN
           pack_size = ntids
        ELSE
           pack_size = ntids - (ntids - 1 + jn - jptra)
        END IF

        CALL mpplnk_my(tra(1,1,1,jn), pack_size,1,1)

#  else

!!   ... T-point, 3D array, full array tra(1,1,1,jn) is initialised

        CALL lbc( tra(1,1,1,jn), 1, 1, 1, 1, jpk, 1 )

#endif


!!!$omp   parallel default(none) private(mytid,ji,jj,jk)
!!!$omp&      shared(jn,jpk,jpj,jpi,trn,trb,tra,tmask,e3t,e3t_back) 

#ifdef __OPENMP1
        mytid = omp_get_thread_num()  ! take the thread ID
#else
      PACK_LOOP1: DO jp=1,ntids
       mytid=jp-1
#endif
      IF( mytid + jn <= jptra ) THEN


        DO jk = 1,jpk
          DO jj = 1,jpj
            DO ji = 1,jpi

            tra(ji,jj,jk,jn+mytid) = tra(ji,jj,jk,jn+mytid)*e3t_back(ji,jj,jk)/e3t(ji,jj,jk)
            trb(ji,jj,jk,jn+mytid) = tra(ji,jj,jk,jn+mytid)
            trn(ji,jj,jk,jn+mytid) = tra(ji,jj,jk,jn+mytid)*tmask(ji,jj,jk)
            tra(ji,jj,jk,jn+mytid) = 0.e0

            END DO
          END DO
        END DO

      END IF
!!!$omp end parallel
#ifdef __OPENMP1
#else
      END DO PACK_LOOP1
      mytid =0
#endif


!! END of tracer slab
!! ==================

       END DO TRACER_LOOP


       trcnxtparttime = MPI_WTIME() - trcnxtparttime ! cronometer-stop
       trcnxttottime = trcnxttottime + trcnxtparttime


      END SUBROUTINE trcnxt