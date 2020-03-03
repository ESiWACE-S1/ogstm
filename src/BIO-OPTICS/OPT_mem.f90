       MODULE OPT_mem 

       USE modul_param 
       USE myalloc

#ifdef Mem_Monitor
       USE check_mem
       USE iso_c_binding
#endif

       IMPLICIT NONE

       public


      INTEGER, allocatable :: itabe(:),imaske(:,:) 
      double precision, allocatable :: zpar(:,:),xEPS_ogstm(:,:)
      double precision, allocatable :: zpar0m(:),zpar100(:) 
      double precision, allocatable :: kef(:,:)
      double precision, allocatable :: kextIO(:,:,:)
      real, allocatable :: zkef_f (:,:)
  
 
      integer, parameter            :: nchl=4 
      integer, parameter            :: nlt=33                     
      integer                       :: lam(33)
      double precision              :: WtoQ(33)
! Radiative transfer model parameter OASIM Native coordinates
      double precision              :: Ed_0m_COARSE(33,12,18,48), Es_0m_COARSE(33,12,18,48) ! lon, lat, day period, wave length
      double precision              :: OASIM_lon(18,48), OASIM_lat(18,48)  
! Radiative transfer model parameter OGSTM coordinates    
      double precision,allocatable  :: Ed_0m(:,:,:), Es_0m(:,:,:) ! wav, lat, lon
      
      INTEGER                       :: day_RTcheck
! in-water model
      INTEGER                       :: it_check
      double precision              :: aw(33),bw(33)
      double precision              :: ac(4,33),bc(4,33)
      double precision              :: acdom(33)
! Variables related to computation of solar zenith angle
      double precision              :: rad 
      integer                       :: imon, nutime 
      double precision              :: dpsi, eps
      double precision,allocatable  :: up(:,:,:),no(:,:,:),ea(:,:,:)

! Avergae cosine computation
      double precision, parameter  :: refrac_idx = 1.341D0
! Constant of aberration
      double precision, parameter  :: xk = 0.0056932D0
!  compute irradiance every hours
      logical                      ::  ifst = .TRUE.
      integer, parameter           ::  nstps1 = 5
      double precision             ::  delmin, hrsec, hrsrt, hrend, delh, delx   
      integer                      ::  nstps

      double precision,allocatable  :: Edaux(:), Esaux(:)
      double precision,allocatable  :: cd(:,:),Cs(:,:),Bu(:,:),Cu(:,:),Bs(:,:),Fd(:,:),Bd(:,:) 
      double precision,allocatable  :: au(:,:),as(:,:),bquad(:,:),cquad(:,:),sqarg(:,:)
      double precision,allocatable  :: inhoD(:,:),inhox(:,:),inhoy(:,:)
      double precision,allocatable  :: D(:,:),a_m(:,:),a_p(:,:)
      double precision,allocatable  :: r_m(:,:),r_p(:,:)
      double precision,allocatable  :: e_m(:,:),e_p(:,:)
      double precision,allocatable  :: zeta0(:),eta0(:)
      double precision,allocatable  :: alpha(:,:),beta(:,:),gamm(:,:),delta(:,:)
      double precision,allocatable  :: epsRT(:,:),zeta(:,:),eta(:,:),theta(:,:)
!     double precision,allocatable  :: vD(:,:),vL(:,:),vU(:,:),WW(:,:),WW1(:,:)
!     double precision,allocatable  :: sol(:,:),sol_p(:,:),sol_m(:,:)
      double precision,allocatable  :: err_RT(:)
! Additional variables for approximate model
      double precision, allocatable        :: a1(:,:),a2(:,:),S(:,:)    
      double precision, allocatable        :: SEdz(:,:),a2ma1(:,:),rM(:,:),rN(:,:),c2(:,:) 
      double precision, allocatable        :: Ta2z(:,:), Eutmp(:,:)

! Outputs of radiative transfer model 
      double precision,allocatable  :: Ed(:,:,:,:), Es(:,:,:,:), Eu(:,:,:,:) ! depth, lat, lon, wave length
      double precision,allocatable  :: PAR(:,:,:,:) ! depth, lat, lon, phyto
      double precision,allocatable  :: Ed_DIA_IO(:,:,:,:),Es_DIA_IO(:,:,:,:),Eu_DIA_IO(:,:,:,:)
      double precision,allocatable  :: Ed_DIA_IO_HIGH(:,:,:,:),Es_DIA_IO_HIGH(:,:,:,:),Eu_DIA_IO_HIGH(:,:,:,:)


!----------------------------------------------------------------------
      CONTAINS

      subroutine myalloc_OPT()
      INTEGER  :: err
      double precision  :: aux_mem

! local variables 
      INTEGER           :: nl
      double precision  :: h, c, hc, oavo, hcoavo, rlamm

#ifdef Mem_Monitor
       aux_mem = get_mem(err)
#endif
       allocate(itabe(jpi))         
      
       itabe   = huge(itabe(1))
       allocate(imaske(jpk,jpi))   
       imaske  = huge(imaske(1,1))
!!!$omp parallel default (none) shared(jpk,jpi)
       allocate(zpar(jpk,jpi))     
       zpar    = huge(zpar(1,1))
       allocate(xEPS_ogstm(jpk,jpi))     
       xEPS_ogstm    = huge(xEPS_ogstm(1,1))
       allocate(zpar0m(jpi))        
       zpar0m  = huge(zpar0m(1))
       allocate(zpar100(jpi))       
       zpar100 = huge(zpar100(1))
!!!$omp end parallel

       allocate(kef(jpj,jpi))       
       kef     = huge(kef(1,1))
       allocate(kextIO(jpj,jpi,2))  
       kextIO  = huge(kextIO(1,1,1))

#if ! defined  key_kef
       kef(:,:) = 0.04
#endif

! radiative transfer model

       rad    = 180.0D0/dacos(-1.0D0) ! initialization of radians
       imon   = 1
       nutime = -99999

       allocate(Ed_0m(nlt,jpj,jpi))
       Ed_0m  =huge(Ed_0m(1,1,1))
       allocate(Es_0m(nlt,jpj,jpi))
       Es_0m  =huge(Es_0m(1,1,1))

       allocate(up(jpj,jpi,3))
       up     =huge(up(1,1,1))

       allocate(no(jpj,jpi,3))
       no     =huge(no(1,1,1))

       allocate(ea(jpj,jpi,3))
       ea     =huge(ea(1,1,1))

       call lidata()

       allocate(Edaux(nlt))
       allocate(Esaux(nlt))
       allocate(cd(jpk,nlt),Cs(jpk,nlt),Bu(jpk,nlt),Cu(jpk,nlt),Bs(jpk,nlt),Fd(jpk,nlt),Bd(jpk,nlt))
       allocate(au(jpk,nlt),as(jpk,nlt),bquad(jpk,nlt),cquad(jpk,nlt),sqarg(jpk,nlt))
       allocate(inhoD(jpk,nlt),inhox(jpk,nlt),inhoy(jpk,nlt))
       allocate(D(jpk,nlt),a_m(jpk,nlt),a_p(jpk,nlt))
       allocate(r_m(jpk,nlt),r_p(jpk,nlt))
       allocate(e_m(jpk,nlt),e_p(jpk,nlt))
       allocate(zeta0(nlt),eta0(nlt))
       allocate(alpha(jpk-1,nlt),beta(jpk-1,nlt),gamm(jpk-1,nlt),delta(jpk-1,nlt))
       allocate(epsRT(jpk-1,nlt),zeta(jpk-1,nlt),eta(jpk-1,nlt),theta(jpk-1,nlt))
!      allocate(vD(2*jpk-1,nlt),vL(2*jpk-1,nlt),vU(2*jpk-1,nlt))
!      allocate(WW(2*jpk-1,nlt), WW1(2*jpk-1,nlt))
!      allocate(sol(2*jpk-1,nlt),sol_p(jpk,nlt),sol_m(jpk,nlt))
       allocate(err_RT(nlt))
! Additional variables for approximate model
       allocate(a1(jpk,nlt),a2(jpk,nlt),S(jpk,nlt))
       allocate(SEdz(jpk,nlt),a2ma1(jpk,nlt),rM(jpk,nlt),rN(jpk,nlt),c2(jpk,nlt))
       allocate(Ta2z(jpk,nlt), Eutmp(jpk,nlt))

! Allocate output variables
       allocate(Ed(jpk,jpj,jpi,nlt),Es(jpk,jpj,jpi,nlt),Eu(jpk,jpj,jpi,nlt))
       allocate(PAR(jpk,jpj,jpi,nchl+1)) ! last index total par
       allocate(Ed_DIA_IO(jpk,jpj,jpi,nlt),Es_DIA_IO(jpk,jpj,jpi,nlt),Eu_DIA_IO(jpk,jpj,jpi,nlt))
       allocate(Ed_DIA_IO_HIGH(jpk,jpj,jpi,nlt),Es_DIA_IO_HIGH(jpk,jpj,jpi,nlt),Eu_DIA_IO_HIGH(jpk,jpj,jpi,nlt))


      Ed(:,:,:,:)   = 0.0d0
      Es(:,:,:,:)   = 0.0d0
      Eu(:,:,:,:)   = 0.0d0 
      PAR(:,:,:,:)  = 0.0d0
      Ed_DIA_IO(:,:,:,:)   = 0.0d0
      Es_DIA_IO(:,:,:,:)   = 0.0d0
      Eu_DIA_IO(:,:,:,:)   = 0.0d0
      Ed_DIA_IO_HIGH(:,:,:,:)   = 0.0d0
      Es_DIA_IO_HIGH(:,:,:,:)   = 0.0d0
      Eu_DIA_IO_HIGH(:,:,:,:)   = 0.0d0

      h = 6.6256E-34   !Plancks constant J sec
      c = 2.998E8      !speed of light m/sec
      hc = 1.0D0/(h*c)
      oavo = 1.0D0/6.023E23   ! 1/Avogadros number
      hcoavo = hc*oavo
      do nl = 1,nlt
       rlamm = real(lam(nl),8)*1.0E-9      !lambda in m
       WtoQ(nl) = rlamm*hcoavo*1000000.0D0 !Watts to micro mol quanta conversion
      enddo
        acdom(:)= 0.0D0

        acdom(1)= 0.22551574188177717D0
        acdom(2)= 0.09083684151542067D0
        acdom(3)= 0.059386382359410544D0
        acdom(4)= 0.038825022434750785D0
        acdom(5)= 0.02538262657482852D0
        acdom(6)= 0.016594394321856793D0
        acdom(7)= 0.010848913610160271D0
        acdom(8)= 0.007092691919806757D0
        acdom(9)= 0.004636987672404267D0
        acdom(10)= 0.003031522434237488D0
        acdom(11)= 0.001981917770447754D0
        acdom(12)= 0.0012957179549306537D0
        acdom(13)= 0.0008471012489838992D0
        acdom(14)= 0.0005538092015314285D0
        acdom(15)= 0.0003620637226881347D0
        acdom(16)= 0.0002367063221851343D0
        acdom(17)= 0.00015475144139385152D0
        
        
#ifdef Mem_Monitor
              mem_all=get_mem(err) - aux_mem
#endif
        
      END subroutine myalloc_OPT
        
        

      subroutine clean_memory_opt

          deallocate(itabe)
          deallocate(imaske)
          deallocate(zpar)
          deallocate(xEPS_ogstm)
          deallocate(zpar0m)
          deallocate(zpar100)
          deallocate(kef)
          deallocate(kextIO)

      end subroutine clean_memory_opt



      END MODULE 