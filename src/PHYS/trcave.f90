      SUBROUTINE trcave
      USE myalloc
      USE IO_mem
      USE FN_mem
#ifdef key_mpp
      USE myalloc_mpp
#endif

      implicit none
!     local
      integer jk,jj,ji,jn
      integer :: jn_high, jn_on_all
      REAL(8) ::  Miss_val =1.e20
      REAL(8) :: Realcounter, Realcounterp1

! omp variables
      INTEGER :: mytid, ntids

#ifdef __OPENMP1
      INTEGER ::  omp_get_thread_num, omp_get_num_threads, omp_get_max_threads
      EXTERNAL :: omp_get_thread_num, omp_get_num_threads, omp_get_max_threads
#endif

      ave_partTime = MPI_WTIME()



#ifdef __OPENMP1
      ntids = omp_get_max_threads() ! take the number of threads
      mytid = -1000000
#else
      ntids = 1
      mytid = 0
#endif


!     FIRST, LOW FREQUENCY
      Realcounter   =    REAL(ave_counter_2  , 8)
      Realcounterp1 = 1./REAL(ave_counter_2+1, 8)

      DO jn=1 ,jptra,ntids

!!!$omp parallel default(none) private(jk,jj,ji,mytid)
!!!$omp&                       shared(jpk,jpj,jpi,jn,tmask,traIO,trn,Miss_val,Realcounter,Realcounterp1)


#ifdef __OPENMP1
           mytid = omp_get_thread_num()  ! take the thread ID
#endif
       IF( mytid + jn <= jptra ) then

          DO jk=1, jpk
             DO jj=1, jpj
                DO ji=1, jpi
               IF(tmask(jk,jj,ji) .NE. 0.) THEN
                  traIO(jk,jj,ji,jn+mytid)=(traIO(jk,jj,ji,jn+mytid)*Realcounter+trn(jk,jj,ji,jn+mytid))*Realcounterp1
               ELSE
                  traIO(jk,jj,ji,jn+mytid)=Miss_val
               ENDIF
                END DO
             END DO
          END DO
       ENDIF
!!!$omp    end parallel

      END DO




      Realcounter   =    REAL(ave_counter_1  , 8)! ****************** HIGH FREQUENCY
      Realcounterp1 = 1./REAL(ave_counter_1+1, 8)
      DO jn_high=1 ,jptra_high,ntids

!!!$omp parallel default(none) private(jk,jj,ji,mytid,jn_on_all)
!!!$omp& shared(jpk,jpj,jpi,jn_high,jptra_high,highfreq_table,tmask,traIO_HIGH,trn,Miss_val,Realcounter,Realcounterp1)

#ifdef __OPENMP1
           mytid = omp_get_thread_num()  ! take the thread ID
#endif
       IF( mytid + jn_high <= jptra_high ) then
          jn_on_all = highfreq_table(jn_high+mytid)
          DO jk=1, jpk
             DO jj=1, jpj
                DO ji=1, jpi
               IF(tmask(jk,jj,ji) .NE. 0.) THEN
                  traIO_HIGH(jk,jj,ji,jn_high+mytid)= &
     &           (traIO_HIGH(jk,jj,ji,jn_high+mytid)*Realcounter+trn(jk,jj,ji,jn_on_all))*Realcounterp1
               ELSE
                  traIO_HIGH(jk,jj,ji,jn_high+mytid)=Miss_val
               ENDIF
                END DO
             END DO
          END DO
       ENDIF
!!!$omp    end parallel

      END DO


!     *****************  PHYS *****************************************************
      if (freq_ave_phys.eq.1) then
          Realcounter   =    REAL(ave_counter_1  , 8)
          Realcounterp1 = 1./REAL(ave_counter_1+1, 8)
      else
          Realcounter   =    REAL(ave_counter_2  , 8)
          Realcounterp1 = 1./REAL(ave_counter_2+1, 8)
      endif


      DO jk=1, jpk
       DO jj=1, jpj
          DO ji=1, jpi
             IF(tmask(jk,jj,ji) .NE. 0.) THEN
                snIO (jk,jj,ji)=(snIO (jk,jj,ji)*Realcounter+sn (jk,jj,ji))*Realcounterp1
                tnIO (jk,jj,ji)=(tnIO (jk,jj,ji)*Realcounter+tn (jk,jj,ji))*Realcounterp1
                wnIO (jk,jj,ji)=(wnIO (jk,jj,ji)*Realcounter+wn (jk,jj,ji))*Realcounterp1
                avtIO(jk,jj,ji)=(avtIO(jk,jj,ji)*Realcounter+avt(jk,jj,ji))*Realcounterp1
                e3tIO(jk,jj,ji)=(e3tIO(jk,jj,ji)*Realcounter+e3t(jk,jj,ji))*Realcounterp1
             ELSE
                snIO (jk,jj,ji)=Miss_val
                tnIO (jk,jj,ji)=Miss_val
                wnIO (jk,jj,ji)=Miss_val
                avtIO(jk,jj,ji)=Miss_val
                e3tIO(jk,jj,ji)=Miss_val
             ENDIF


             IF(umask(jk,jj,ji) .NE. 0.) THEN
                unIO(jk,jj,ji)=(unIO(jk,jj,ji)*Realcounter+un(jk,jj,ji))*Realcounterp1
             ELSE
                unIO(jk,jj,ji)=Miss_val
             ENDIF


             IF(vmask(jk,jj,ji) .NE. 0.) THEN
                vnIO(jk,jj,ji)=(vnIO(jk,jj,ji)*Realcounter+vn(jk,jj,ji))*Realcounterp1
             ELSE
                vnIO(jk,jj,ji)=Miss_val
             ENDIF

          END DO
       END DO
      END DO

      DO jj=1, jpj
        DO ji=1, jpi
           IF (tmask(jj,ji,1) .NE. 0.) THEN
               vatmIO(jj,ji)=(vatmIO(jj,ji)*Realcounter+vatm(jj,ji))*Realcounterp1
               empIO (jj,ji)=(empIO (jj,ji)*Realcounter+emp (jj,ji))*Realcounterp1
               qsrIO (jj,ji)=(qsrIO (jj,ji)*Realcounter+qsr (jj,ji))*Realcounterp1
           ELSE
               vatmIO(jj,ji)=Miss_val
               empIO (jj,ji)=Miss_val
               qsrIO (jj,ji)=Miss_val
           ENDIF
        END DO
      END DO

!     *****************  END PHYS *************************************************


!     *****************  DIAGNOSTICS **********************************************

!     FIRST, LOW FREQUENCY

      Realcounter   =    REAL(ave_counter_2  , 8)
      Realcounterp1 = 1./REAL(ave_counter_2+1, 8)

      DO jn=1, jptra_dia,ntids

!!!$omp parallel default(none) private(jk,jj,ji,mytid)
!!!$omp&   shared(jpk,jpj,jpi,jn,tmask,tra_DIA_IO,tra_DIA,Miss_val,Realcounter,Realcounterp1)

#ifdef __OPENMP1
           mytid = omp_get_thread_num()  ! take the thread ID
#endif
      IF( mytid + jn .LE. jptra_dia ) then

         DO jk=1, jpk
            DO jj=1, jpj
               DO ji=1, jpi
                  IF(tmask(jk,jj,ji) .NE. 0.) THEN
                    tra_DIA_IO(jk,jj,ji,jn+mytid)=(tra_DIA_IO(jk,jj,ji,jn+mytid)*Realcounter+ &
     &              tra_DIA(jk,jj,ji,jn+mytid))*Realcounterp1
                  ELSE
                    tra_DIA_IO(jk,jj,ji,jn+mytid)=Miss_val
                  ENDIF
               END DO
            END DO
         END DO
      ENDIF

!!!$omp    end parallel
      END DO

!     *********************  DIAGNOSTICS 2D **********
      DO jn=1, jptra_dia_2d

            DO jj=1, jpj
               DO ji=1, jpi
                  IF(tmask(jj,ji,1) .NE. 0.) THEN ! Warning ! Tested only for surface
                    tra_DIA_2d_IO(jj,ji,jn)=(tra_DIA_2d_IO(jj,ji,jn)*Realcounter+ &
     &              tra_DIA_2d(jj,ji,jn))*Realcounterp1
                  ELSE
                    tra_DIA_2d_IO(jj,ji,jn)=Miss_val
                  ENDIF
               END DO
            END DO

      END DO




      Realcounter   =    REAL(ave_counter_1  , 8) ! ****************** HIGH FREQUENCY
      Realcounterp1 = 1./REAL(ave_counter_1+1, 8)


      DO jn_high=1, jptra_dia_high,ntids

!!!$omp parallel default(none) private(jk,jj,ji,mytid,jn_on_all)
!!!$omp&   shared(jpk,jpj,jpi,jn_high,jptra_dia_high,highfreq_table_dia, tmask,tra_DIA_IO_HIGH,tra_DIA,Miss_val,
!!!$omp&   Realcounter,Realcounterp1)

#ifdef __OPENMP1
           mytid = omp_get_thread_num()  ! take the thread ID
#endif

      IF (mytid + jn_high .LE. jptra_dia_high)  then
          IF (mytid + jn_high .LE. jptra_dia ) then
             jn_on_all = highfreq_table_dia(jn_high+mytid)

             DO jk=1, jpk
             DO jj=1, jpj
             DO ji=1, jpi
                IF(tmask(jk,jj,ji) .NE. 0.) THEN
                   tra_DIA_IO_HIGH(jk,jj,ji,jn_high+mytid)= &
     &            (tra_DIA_IO_HIGH(jk,jj,ji,jn_high+mytid)*Realcounter+tra_DIA(jk,jj,ji,jn_on_all))*Realcounterp1 
                ELSE
                   tra_DIA_IO_HIGH(jk,jj,ji,jn_high+mytid)=Miss_val
                ENDIF
             END DO
             END DO
             END DO
          ENDIF
      ENDIF
!!!$omp    end parallel
      END DO

!     *********************  DIAGNOSTICS 2D **********

      DO jn_high=1, jptra_dia2d_high
             jn_on_all = highfreq_table_dia2d(jn_high)

             DO jj=1, jpj
             DO ji=1, jpi
                IF(tmask(jj,ji,1) .NE. 0.) THEN
                   tra_DIA_2d_IO_HIGH(jj,ji,jn_high)= &
     &            (tra_DIA_2d_IO_HIGH(jj,ji,jn_high)*Realcounter+tra_DIA_2d(jj,ji,jn_on_all))*Realcounterp1
                ELSE
                   tra_DIA_2d_IO_HIGH(jj,ji,jn_high)=Miss_val
                ENDIF
             END DO
             END DO

      END DO


      ave_partTime = MPI_WTIME() - ave_partTime
      ave_TotTime = ave_TotTime  + ave_partTime

      END SUBROUTINE trcave
