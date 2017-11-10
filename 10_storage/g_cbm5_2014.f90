!
!	g_cbm5_2014.f90
!	
!
!  Creado por Jose Agustin Garcia Reynoso el 12/07/17.
!
!
!  Proposito:
!            Guarda los datos del inventari para el 
!            mecanismo CBM05 en formato netcdf
!
! ifort -O2 -axAVX -lnetcdff -L$NETCDF/lib -I$NETCDF/include  g_cbm5_2014.f90 -o cbm5.exe
!
!   Si son mas de 5 capas arreglar linea 219
!      eeft(i,j,ii,ih,9-levl)=eft(i,j,ii,ih,9-levl)+edum(ih)/WTM(ii)
!
!   Actualizacion de xlat, xlon             26/08/2012
!   Conversion de unidades en aerosoles     04/10/2012
!   Inclusion de NO2 en las emisiones       19/02/2014
!   Inclusion de poblacion en la salida     10/06/2014
!   Para año 2014, ns, ipm, icn             12/07/2017
!   Dos capas en puntuales                  18707/2017
!   Se incluyen NO y NO2 de moviles         01/11/2017
!
module vars
    integer :: nf    ! number of files antropogenic
    integer :: ns    ! number of compounds
    integer ::ncel   ! number of cell in the grid
    integer ::nl     ! number of lines in files
    integer ::radm   ! number of Mechanism classes
    integer :: nh    !  hours in a day
    integer :: nx,ny ! grid dimensions
    integer :: ncty  ! number of point stations
    integer :: idcf  ! ID cell in file
    integer :: zlev       ! Layer of emission (1 to 8) 8 lower 1 upper
    integer,parameter :: ipm=23  ! Posicion del archivo PM2.5
    integer,parameter :: icn=30    ! Posicion archivo CN del INEM
    integer,parameter :: jcn=28    ! Posicion archivo CN de especiacion
    integer,parameter :: imt=29    ! Posicion archivo CH4 del INEM
    integer,parameter :: jmt=7     ! Posicion archivo CH4 de especiacion
    integer,allocatable :: idcg(:) ! ID cell in grid
    integer,allocatable:: utmz(:),utmzd(:,:)  !utmz
    real,allocatable:: eft(:,:,:,:,:)  ! emissions by nx,ny,file,nh,level
    real,allocatable :: lon(:),lat(:),pop(:)
    real,allocatable :: utmx(:),utmy(:)
    real,allocatable :: xlon(:,:),xlat(:,:),pob(:,:)
    real,allocatable :: utmxd(:,:),utmyd(:,:)

    parameter(nf=30,ns=28,radm=ns+5,nh=24)
	
    character(len=3) :: cday
    character(len=11),dimension(radm):: ename=(/'E_CO   ','E_NH3  ','E_NO   ', &
    'E_NO2  ','E_SO2  ','E_ALD2 ','E_CH4  ','E_ALDX ','E_ETH  ','E_ETHA ', &
    'E_ETOH ','E_IOLE ','E_MEOH ','E_HCHO ','E_ISOP ','E_OLE  ','E_PAR  ', &
    'E_TERP ','E_TOL  ','E_XYL  ','E_CO2  ', &
    'E_PM_10','E_PM25 ','E_SO4I ','E_NO3I ','E_PM25I',&
    'E_ORGI ','E_ECI  ','E_SO4J ','E_NO3J ','E_PM25J','E_ORGJ ','E_ECJ  '/)
    character(len=16),dimension(radm):: cname=(/'Carbon Monoxide ','NH3             ','NO              ', &
    'NO2  ','SO2  ','Acetaldehyde','METHANE','C3+Aldehydes','Ethene','Ethane', &
    'Ethanol','Internal OLE  ','Methanol','HCHO ','Isoprene','TOB (R-C=C)','Paraffin (C-C)', &
    'Terpenes','Toluene+others','Xylene+others','Carbon Dioxide', &
    'PM_10','PM_25 ','Sulfates ','Nitrates ','PM25I',&
    'Organic ','Elemental Carbon','SulfatesJ','NitratesJ','PM25J','Organic','Elemental Carbon'/)
    character (len=19) :: current_date,current_datem,mecha

    common /domain/ ncel,nl,nx,ny,zlev
    common /date/ current_date,cday,mecha,cname
end module vars

program guarda_nc
use vars
use netcdf

	call lee
	
	!call calculos
	
	call store
contains
subroutine lee
    IMPLICIT NONE
    integer :: ii,i,j,k,levl,levld,ih
    integer :: is     ! indice de compuesto
    integer :: iunit=14
    real ::rdum
    real,dimension(nh)::edum
    real,dimension(ns)::wtm
    real,dimension(nf)::scala,scalm,scalp
    character(len=46) :: description
    character(len=13) cdum
    character(len=17),dimension(nf):: fnameA,fnameM,fnameP
    data fnameA /&
    & 'TACO__2014.csv'  ,'TANH3_2014.csv' ,'TANOx_2014.csv'  ,'TANOx_2014.csv','TASO2_2014.csv',&
	& 'CBM05_ALD2_A.txt','CBM05_CH4_A.txt','CBM05_ALDX_A.txt','CBM05_ETH_A.txt',&
	& 'CBM05_ETHA_A.txt','CBM05_ETOH_A.txt','CBM05_IOLE_A.txt','CBM05_MEOH_A.txt',&
	& 'CBM05_FORM_A.txt','CBM05_ISOP_A.txt','CBM05_OLE_A.txt','CBM05_PAR_A.txt',&
	& 'CBM05_TERP_A.txt','CBM05_TOL_A.txt', 'CBM05_XYL_A.txt',&
	& 'TACO2_2014.csv' ,'TAPM102014.csv','TAPM2_2014.csv',&
	& 'GSO4_A.txt','PNO3_A.txt','OTHE_A.txt','POA_A.txt','PEC_A.txt',&
    & 'TACH4_2014.csv','TACN__2014.csv'/
	data fnameM /'TMCO__2014.csv','TMNH3_2014.csv','TMNO_2014.csv','TMNO2_2014.csv','TMSO2_2014.csv',&
    & 'CBM05_ALD2_M.txt','CBM05_CH4_M.txt','CBM05_ALDX_M.txt' ,'CBM05_ETH_M.txt',&
    & 'CBM05_ETHA_M.txt','CBM05_ETOH_M.txt','CBM05_IOLE_M.txt','CBM05_MEOH_M.txt',&
    & 'CBM05_FORM_M.txt','CBM05_ISOP_M.txt','CBM05_OLE_M.txt','CBM05_PAR_M.txt',&
    & 'CBM05_TERP_M.txt','CBM05_TOL_M.txt','CBM05_XYL_M.txt',&
    & 'TMCO2_2014.csv','TMPM102014.csv','TMPM2_2014.csv',&
	& 'GSO4_M.txt','PNO3_M.txt','OTHE_M.txt','POA_M.txt','PEC_M.txt',&
    & 'TMCH4_2014.csv','TMCN__2014.csv'/
    data fnameP /'T_ANNCO.csv','T_ANNNH3.csv','T_ANNNOX.csv','T_ANNNOX.csv','T_ANNSO2.csv',&
    & 'CBM05_ALD2_P.txt','CBM05_CH4_P.txt','CBM05_ALDX_P.txt' ,'CBM05_ETH_P.txt',&
    & 'CBM05_ETHA_P.txt','CBM05_ETOH_P.txt','CBM05_IOLE_P.txt','CBM05_MEOH_P.txt',&
    & 'CBM05_FORM_P.txt','CBM05_ISOP_P.txt','CBM05_OLE_P.txt','CBM05_PAR_P.txt',&
    & 'CBM05_TERP_P.txt','CBM05_TOL_P.txt','CBM05_XYL_P.txt',&
    & 'T_ANNCO2.csv','T_ANNPM10.csv','T_ANNPM25.csv', &
	& 'GSO4_P.txt','PNO3_P.txt','OTHE_P.txt','POA_P.txt','PEC_P.txt',&
    & 'T_ANNCH4.csv','T_ANNCN.csv'/
! Mole weight
       DATA WTM /28., 17., 30., 46., 64.,32.,  16., 32., 32.,32.,32.,&   !
	   &         64., 16., 16., 80., 32.,16., 160.,112.,128., 44.,&
	   &      3600.,3600.,3600.,3600.,3600.,3600.,3600./ ! MW 3600 for unit conversion to ug/s
!    SCALA      CO   NH3  NO   NO2  SO2 ALD2   CH4  ALDx  ETH ETHA ETOH
!             IOLE  MEOH HCHO ISOP  OLE  PAR   TERP  TOL  XYL  CO2
!             PM10 PM2.5 PSO4 PNO3 OTHER POA   PEC  CH4   CN
DATA scala /  1.00,1.00,1.00,1.00,1.00,1.00,  1.00,1.00,1.00,1.00,1.00,& !
&             1.00,1.00,1.00,1.00,1.00,1.00,  1.00,1.00,1.00,1.00,&
&             1.00,1.00,1.00,1.00,1.00,1.00,  1.00,1.00,1.00/
DATA scalm /  1.00,1.00,1.00,1.00,1.00,1.00,  1.00,1.00,1.00,1.00,1.00,& !
&             1.00,1.00,1.00,1.00,1.00,1.00,  1.00,1.00,1.00,10.0,&
&             1.00,1.00,1.00,1.00,1.00,1.00,  1.00,1.00,1.00/
DATA scalp /  1.00,1.00,1.00,1.00,1.00,1.00,  1.00,1.00,1.00,1.00,1.00,& !
&             1.00,1.00,1.00,1.00,1.00,1.00,  1.00,1.00,1.00,0.00,&
&             1.00,1.00,1.00,1.00,1.00,1.00,  1.00,0.00,0.00/
       mecha="CMB05"
	write(6,*)' >>>> Reading file -  localiza.csv ---------'

	open (unit=10,file='localiza.csv',status='old',action='read')
	read (10,*) cdum  !Header
	read (10,*) nx,ny  !Header
	ncel=nx*ny
	allocate(idcg(ncel),lon(ncel),lat(ncel),pop(ncel))
   allocate(utmx(ncel),utmy(ncel),utmz(ncel))
	allocate(xlon(nx,ny),xlat(nx,ny),pob(nx,ny))
   allocate(utmxd(nx,ny),utmyd(nx,ny),utmzd(nx,ny))
	allocate(eft(nx,ny,nf,nh,8))
    zlev=0
    eft=0
	do k=1,ncel
	read(10,*) idcg(k),lon(k),lat(k),i,pop(k),utmx(k),utmy(k),utmz(k)
	end do
!
    do i=1,nx
        do j=1,ny
            k=i+(j-1)*nx
            xlon(i,j)=lon(k)
            xlat(i,j)=lat(k)
            pob(i,j)=pop(k)
            utmxd(i,j)=utmx(k)
            utmyd(i,j)=utmy(k)
            utmzd(i,j)=utmz(k)
        end do
    end do
!   print *,ncel,xlon(1,1),xlat(1,1)
	close(10)
	do ii=1,nf
		open(11,file=fnameA(ii),status='OLD',action='READ')
        read(11,*)cdum
		if (ii.eq.1)then
            read(11,*)j,current_date,cday  !j number of lines in file
			print *,current_date,' ',cday
        else    
            read(11,*)j,current_date
        end if
!
        is= ii
        if(ii.eq.icn) is=jcn  ! suma todo el Carbono Negro
        if(ii.eq.imt) is=jmt   ! suma todo el Metano
        write(6,'(i4,x,A,A,I3,I3)') ii,fnameA(ii),current_date,is
		do
		 if(ii.eq.ipm) then !for PM2.5
		 read(11,*,END=100) idcf,rdum,(edum(ih),ih=1,nh)
		 else
		 read(11,*,END=100) idcf,(edum(ih),ih=1,nh)
		 end if
		 k=0
		 busca: do j=1,ny
		  do i=1,nx
			k=k+1
			if(idcg(k).eq.idcf) then
			  do ih=1,nh
				eft(i,j,is,ih,1)=eft(i,j,is,ih,1)+edum(ih)/WTM(is)*scala(ii) ! Emission from kg to gmol
              end do
			  exit busca
			end if
		 end do
		end do busca
		end do
 100 close(11)
 		open(11,file=fnameM(ii),status='OLD',action='READ')
		read(11,*)cdum
		if (ii.eq.1)then
            read(11,*)j,current_date,cday  !j number of lines in file
			!print *,current_date,cday
        else    
            read(11,*)j,current_date
        end if
        write(6,'(i4,x,A,A)') ii,fnameM(ii),current_date
		do 
		 if(ii.eq.ipm) then !for PM2.5
		 read(11,*,END=200) idcf,rdum,(edum(ih),ih=1,nh)
		 else
		 read(11,*,END=200) idcf,(edum(ih),ih=1,nh)
		 end if
		 k=0
		 busca2: do j=1,ny
		  do i=1,nx
			k=k+1
			if(idcg(k).eq.idcf) then
			  do ih=1,nh
                ! Emission from g to gmol by 1/WTM
                eft(i,j,is,ih,1)=eft(i,j,is,ih,1)+edum(ih)/WTM(is)*scalm(ii)
			  end do
			  exit busca2
			end if
		 end do
		end do busca2
		end do	
 200 close(11)
!  For point sources
!	if (ii.ne.2) then
		open(11,file=fnameP(ii),status='OLD',action='READ')
		read(11,*)cdum
		if (ii.eq.1)then
            read(11,*)j,current_date,cday  !j number of lines in file
			!print *,current_date,cday
        else    
            read(11,*)j,current_date
        end if
        write(6,'(i4,x,A,A)') ii,fnameP(ii),current_date
		do 
		 if(ii.eq.ipm) then   !for PM2.5
		 read(11,*,END=300) idcf,rdum,levl,(edum(ih),ih=1,nh),levld
         !print *,idcf,rdum,levl,(edum(ih),ih=1,nh)
		 else
		 read(11,*,END=300) idcf,levl,(edum(ih),ih=1,nh),levld
		 end if
		 k=0
		 busca3: do j=1,ny
		  do i=1,nx
			k=k+1
			if(idcg(k).eq.idcf) then
			  do ih=1,nh
                ! Emission from g to gmol by 1/WTM
            if(ih.gt.9 .and. ih.lt.19) then
              eft(i,j,is,ih,levl)=eft(i,j,is,ih,levl)+edum(ih)/WTM(is)*scalp(ii)
            else
              eft(i,j,is,ih,levld)=eft(i,j,is,ih,levld)+edum(ih)/WTM(is)*scalp(ii)
            end if
			  end do
              zlev =max(zlev,levl,levld)
			  exit busca3
			end if
		 end do
		end do busca3
		end do
 300 close(11)
!	end if
	end do! ii nf
	
	return

end subroutine lee

subroutine calculos
	IMPLICIT NONE

end subroutine calculos

subroutine store
    IMPLICIT NONE
      integer :: NDIMS
      parameter (NDIMS=6)
      integer :: i,j,k,l
      integer :: ncid
      integer :: periodo,iit,eit,it
      integer :: ikk
      integer :: dimids2(2),dimids3(3),dimids4(4)
      integer,dimension(radm+1):: id_var
      integer :: id_varlong,id_varlat,id_varpop
      integer :: id_utmx,id_utmy,id_utmz
      integer :: id,iu
      integer :: isp(radm)
      integer,dimension(NDIMS):: dim,id_dim
      real,ALLOCATABLE :: ea(:,:,:,:)
      real :: CDIM=3.0  ! celdimension in km
      character (len=19),dimension(NDIMS) ::sdim
      character(len=39):: FILE_NAME
      character(len=19),dimension(1,1)::Times
      character(len=19):: iTime
      character(8)  :: date
      character(10) :: time
      character(24) :: hoy
  	   DATA isp / 1, 2, 3, 4, 5, 6, 7, 8, 9,10, &
                 11,12,13,14,15, 16,17,18,19,20, &
                 21,22,23,24,25, 26,27,28,29,30, &
				 31,32,33/

    data sdim /"Time               ","DateStrLen         ","west_east          ",&
	&          "south_north        ","bottom_top         ","emissions_zdim_stag"/	

	 print *,"Guarda Archivo"	 
! ******************************************************************
    call date_and_time(date,time)
     hoy=date(7:8)//'-'//mes(date(5:6))//'-'//date(1:4)//' '//time(1:2)//':'//time(3:4)//':'//time(5:10)
    print *,hoy
    !write(current_date(4:4),'(A1)')char(6+48)
     do periodo=1,1!2
	  if(periodo.eq.1) then
        FILE_NAME='wrfchemi.d01.'//trim(mecha)//'.'//current_date(1:19)         !******
	   iit= 0
	   eit= 23 !11
	   iTime=current_date
	  else if(periodo.eq.2) then
	   iit=12
	   eit=23
       write(iTime(12:13),'(I2)') iit
        FILE_NAME='wrfchemi.d01.'//trim(mecha)//'.'//iTime
	 end if
	  ! Open NETCDF emissions file	
       call check( nf90_create(FILE_NAME, nf90_clobber, ncid) )
!     Define dimensiones
		  dim(1)=1
		  dim(2)=19
		  dim(3)=nx
		  dim(4)=ny
		  dim(5)=1!mkx
		  dim(6)=zlev! !8
         if(.not.ALLOCATED(ea)) allocate (ea(dim(3),dim(4),dim(6),dim(1)))
		 call check( nf90_def_dim(ncid,sdim(1), NF90_UNLIMITED, id_dim(1)) )
       do i=2,NDIMS
         call check( nf90_def_dim(ncid, sdim(i), dim(i), id_dim(i)) )
       end do

    dimids2 = (/id_dim(2),id_dim(1)/)
    dimids3 = (/id_dim(3),id_dim(2),id_dim(1) /)
    dimids4 = (/id_dim(3),id_dim(4),id_dim(6),id_dim(1)/)
    print *,"Attributos Globales NF90_GLOBAL"
    !Attributos Globales NF90_GLOBAL
    call check( nf90_put_att(ncid, NF90_GLOBAL, "TITLE","EI 2014 emissions for Cd Juarez Area"))
    call check( nf90_put_att(ncid, NF90_GLOBAL, "START_DATE",iTime))
    call check( nf90_put_att(ncid, NF90_GLOBAL, "DAY ",cday))
    call check( nf90_put_att(ncid, NF90_GLOBAL, "SIMULATION_START_DATE",iTime))
    call check( nf90_put_att(ncid, NF90_GLOBAL, "WEST-EAST_GRID_DIMENSION",nx))
    call check( nf90_put_att(ncid, NF90_GLOBAL, "SOUTH-NORTH_GRID_DIMENSION",ny))
    call check( nf90_put_att(ncid, NF90_GLOBAL, "BOTTOM-TOP_GRID_DIMENSION",1))
    call check( nf90_put_att(ncid, NF90_GLOBAL, "DX",CDIM*1000))
    call check( nf90_put_att(ncid, NF90_GLOBAL, "DY",CDIM*1000))
    call check( nf90_put_att(ncid, NF90_GLOBAL, "CEN_LAT",(MAXVAL(lat)+MINVAL(lat))/2))
    call check( nf90_put_att(ncid, NF90_GLOBAL, "CEN_LON",(MAXVAL(lon)+MINVAL(lon))/2))
    call check( nf90_put_att(ncid, NF90_GLOBAL, "TRUELAT1",17.5))
    call check( nf90_put_att(ncid, NF90_GLOBAL, "TRUELAT2",29.5))
    call check( nf90_put_att(ncid, NF90_GLOBAL, "MOAD_CEN_LAT",24.020222))
    call check( nf90_put_att(ncid, NF90_GLOBAL, "STAND_LON",-102.036352))
    call check( nf90_put_att(ncid, NF90_GLOBAL, "POLE_LAT",90.))
    call check( nf90_put_att(ncid, NF90_GLOBAL, "POLE_LON",0.))
    call check( nf90_put_att(ncid, NF90_GLOBAL, "GRIDTYPE","C"))
    call check( nf90_put_att(ncid, NF90_GLOBAL, "GMT",12.))
    call check( nf90_put_att(ncid, NF90_GLOBAL, "JULYR",2014))
    call check( nf90_put_att(ncid, NF90_GLOBAL, "JULDAY",40))
    call check( nf90_put_att(ncid, NF90_GLOBAL, "MAP_PROJ",1))
    call check( nf90_put_att(ncid, NF90_GLOBAL, "MMINLU","USGS"))
    call check( nf90_put_att(ncid, NF90_GLOBAL, "MECHANISM",mecha))
    call check( nf90_put_att(ncid, NF90_GLOBAL, "CREATION_DATE",hoy))

	print *,"Define las variables"
!  Define las variables
	call check( nf90_def_var(ncid, "Times", NF90_CHAR, dimids2,id_var(radm+1) ) )
!  Attributos para cada variable 
    call check( nf90_def_var(ncid, "XLONG", NF90_REAL,(/id_dim(3),id_dim(4),id_dim(1)/),id_varlong ) )
       ! Assign  attributes
      call check( nf90_put_att(ncid, id_varlong, "FieldType", 104 ) )
      call check( nf90_put_att(ncid, id_varlong, "MemoryOrder", "XYZ") )
      call check( nf90_put_att(ncid, id_varlong, "description", "LONGITUDE, WEST IS NEGATIVE") )
      call check( nf90_put_att(ncid, id_varlong, "units", "degree_east"))
      call check( nf90_put_att(ncid, id_varlong, "axis", "X") )
    call check( nf90_def_var(ncid, "XLAT", NF90_REAL,(/id_dim(3),id_dim(4),id_dim(1)/),id_varlat ) )
       ! Assign  attributes
      call check( nf90_put_att(ncid, id_varlat, "FieldType", 104 ) )
      call check( nf90_put_att(ncid, id_varlat, "MemoryOrder", "XYZ") )
      call check( nf90_put_att(ncid, id_varlat, "description", "LATITUDE, SOUTH IS NEGATIVE") )
      call check( nf90_put_att(ncid, id_varlat, "units", "degree_north"))
      call check( nf90_put_att(ncid, id_varlat, "axis", "Y") )
     print *," Pob"
    call check( nf90_def_var(ncid,"POB",NF90_REAL,(/id_dim(3),id_dim(4),id_dim(1)/) ,id_varpop ) )
        ! Assign  attributes
      call check( nf90_put_att(ncid, id_varpop, "FieldType", 104 ) )
      call check( nf90_put_att(ncid, id_varpop, "MemoryOrder", "XYZ") )
      call check(nf90_put_att(ncid,id_varpop,"description","Population in each grid"))
      call check( nf90_put_att(ncid, id_varpop, "units", "number"))
  ! Para Mercator
    call check( nf90_def_var(ncid, "UTMx", NF90_REAL,(/id_dim(3),id_dim(4)/),id_utmx ) )
    ! Assign  attributes
      call check( nf90_put_att(ncid, id_utmx, "FieldType", 104 ) )
      call check( nf90_put_att(ncid, id_utmx, "MemoryOrder", "XYZ") )
      call check( nf90_put_att(ncid, id_utmx, "description", "UTM coordinate west-east") )
      call check( nf90_put_att(ncid, id_utmx, "units", "km"))
      call check( nf90_put_att(ncid, id_utmx, "axis", "X") )
    call check( nf90_def_var(ncid, "UTMy", NF90_REAL,(/id_dim(3),id_dim(4)/),id_utmy ) )
    ! Assign  attributes
      call check( nf90_put_att(ncid, id_utmy, "FieldType", 104 ) )
      call check( nf90_put_att(ncid, id_utmy, "MemoryOrder", "XYZ") )
      call check( nf90_put_att(ncid, id_utmy, "description", "UTM coordinate sotuth-north") )
      call check( nf90_put_att(ncid, id_utmy, "units", "km"))
      call check( nf90_put_att(ncid, id_utmy, "axis", "Y") )
    call check( nf90_def_var(ncid, "UTMz", NF90_INT,(/id_dim(3),id_dim(4)/),id_utmz ) )
    ! Assign  attributes
      call check( nf90_put_att(ncid, id_utmz, "FieldType", 104 ) )
      call check( nf90_put_att(ncid, id_utmz, "MemoryOrder", "XYZ") )
      call check( nf90_put_att(ncid, id_utmz, "description", "UTM Zone") )
      call check( nf90_put_att(ncid, id_utmz, "units", "None"))
	do i=1,radm
		if(i.lt.ipm-1) then
			call crea_attr(ncid,4,dimids4,ename(i),cname(i),id_var(i))
		else
			call crea_attr2(ncid,4,dimids4,ename(i),cname(i),id_var(i))
		end if
	end do
!
!   Terminan definiciones
		call check( nf90_enddef(ncid) )
!  Coordenadas Mercator UTM
    call check( nf90_put_var(ncid, id_utmx,utmxd,start=(/1,1/)) )
    call check( nf90_put_var(ncid, id_utmy,utmyd,start=(/1,1/)) )
    call check( nf90_put_var(ncid, id_utmz,utmzd,start=(/1,1/)) )

!    Inicia loop de tiempo

tiempo: do it=iit,eit
		write(6,'(A,x,I3)')'TIEMPO: ', it
        gases: do ikk=1,ipm-2
			ea=0.0
		if(ikk.eq.1) then
		      if (it.lt.10) then
			  write(current_date(13:13),'(A1)')char(it+48)
			    else
		        id = int((it)/10)+48 !  Decenas
                iu = it-10*int((it)/10)+48 ! unidades
			  write(current_date(12:13),'(A1,A1)')char(id),char(iu)
			  end if 

  	      Times(1,1)=current_date(1:19)
			  if (periodo.eq. 1) then
            call check( nf90_put_var(ncid,id_var(radm+1),Times,start=(/1,it+1/)) )
            call check( nf90_put_var(ncid, id_varlong,xlon,start=(/1,1,it+1/)) )
            call check( nf90_put_var(ncid, id_varlat,xlat,start=(/1,1,it+1/)) )
            call check( nf90_put_var(ncid, id_varpop,pob,  start=(/1,1,it+1/)) )
			  else
            call check( nf90_put_var(ncid,id_var(radm+1),Times,start=(/1,it-11/)) )
            call check( nf90_put_var(ncid, id_varlong,xlon,start=(/1,1,it-11/)) )
            call check( nf90_put_var(ncid, id_varlat,xlat,start=(/1,1,it-11/)) )
            call check( nf90_put_var(ncid, id_varpop,pob,start=(/1,1,it-11/)) )
			  endif
            end if   ! for kk == 1
            do i=1, nx
                do j=1, ny
				  do l=1,zlev
                   ea(i,j,l,1)=eft(i,j,ikk,it+1,l) /(CDIM*CDIM)
				  end do
                end do
            end do
            if(periodo.eq.1) then
                call check( nf90_put_var(ncid, id_var(isp(ikk)),ea,start=(/1,1,1,it+1/)) )
            else
                call check( nf90_put_var(ncid, id_var(isp(ikk)),ea,start=(/1,1,1,it-11/)) )        !******
            endif
		 end do gases
        aerosol: do ikk=ipm-1,ns
			ea=0.0
            do i=1, nx
                do j=1, ny
			  do l=1,zlev
				ea(i,j,l,1)=eft(i,j,ikk,it+1,l) /(CDIM*CDIM) !entre 3x3 km
			  end do
                end do
            end do
!
            if(periodo.eq.1) then
                call check( nf90_put_var(ncid, id_var(isp(ikk)),ea*0.8,start=(/1,1,1,it+1/)) )
                call check( nf90_put_var(ncid, id_var(isp(ikk+5)),ea*0.2,start=(/1,1,1,it+1/)) )
            else
                call check( nf90_put_var(ncid, id_var(isp(ikk)),ea*0.8,start=(/1,1,1,it-11/)) )        !******
                call check( nf90_put_var(ncid, id_var(isp(ikk+5)),ea*0.2,start=(/1,1,1,it-11/)) )        !******
            endif
		 end do aerosol
		end do tiempo
        call check( nf90_close(ncid) )
	 end do !periodo
    deallocate(ea)

end subroutine store

subroutine check(status)
	integer, intent ( in) :: status
	if(status /= nf90_noerr) then 
		print *, trim(nf90_strerror(status))
		stop 2
	end if
end subroutine check  
!   CCC RRRR  EEEEE   A        A   TTTTT TTTTT RRRR
!  C    R  RR E      A A      A A    T     T   R  RR
! C     RRRR  EEEE  AAAAA    AAAAA   T     T   RRRR
!  C    R  R  E     A   A    A   A   T     T   R  R
!   CCC R   R EEEEE A   A____A   A   T     T   R   R
	  subroutine crea_attr(ncid,idm,dimids,svar,cname,id_var)
	  use netcdf
      implicit none
	  integer , INTENT(IN) ::ncid,idm
	  integer, INTENT(out) :: id_var
	  integer, INTENT(IN),dimension(idm):: dimids
	  character(len=*), INTENT(IN)::svar,cname
	  character(len=50) :: cvar
		cvar="Emissions rate of "//trim(cname)
	  
	   call check( nf90_def_var(ncid, svar, NF90_REAL, dimids,id_var ) )
 ! Assign  attributes
        call check( nf90_put_att(ncid, id_var, "FieldType", 104 ) )
        call check( nf90_put_att(ncid, id_var, "MemoryOrder", "XYZ") )
        call check( nf90_put_att(ncid, id_var, "description", Cvar) )
        call check( nf90_put_att(ncid, id_var, "units", "mol km^-2 hr^-1"))
        call check( nf90_put_att(ncid, id_var, "stagger", "Z") )
		call check( nf90_put_att(ncid, id_var, "coordinates", "XLONG XLAT") )
		! print *,"Entro a Attributos de variable",dimids,id,jd
	  return
	  end subroutine crea_attr
!   CCC RRRR  EEEEE   A        A   TTTTT TTTTT RRRR   222
!  C    R  RR E      A A      A A    T     T   R  RR 2   2
! C     RRRR  EEEE  AAAAA    AAAAA   T     T   RRRR     2
!  C    R  R  E     A   A    A   A   T     T   R  R   2
!   CCC R   R EEEEE A   A____A   A   T     T   R   R 22222
	  subroutine crea_attr2(ncid,idm,dimids,svar,cname,id_var)
	  use netcdf
      implicit none
	  integer, INTENT(IN) ::ncid,idm
	  integer, INTENT(out) :: id_var
	  integer,INTENT(IN) ,dimension(idm):: dimids
	  character(len=*),INTENT(IN) ::svar,cname
	  character(len=50) :: cvar
		cvar="EMISSIONS RATE OF "//trim(cname)
	   call check( nf90_def_var(ncid, svar, NF90_REAL, dimids,id_var ) )
 ! Assign  attributes
        call check( nf90_put_att(ncid, id_var, "FieldType", 104 ) )
        call check( nf90_put_att(ncid, id_var, "MemoryOrder", "XYZ") )
        call check( nf90_put_att(ncid, id_var, "description",cvar) )
        call check( nf90_put_att(ncid, id_var, "units", "ug m-2 s-1"))
        call check( nf90_put_att(ncid, id_var, "stagger", "Z") )
		call check( nf90_put_att(ncid, id_var, "coordinates", "XLONG XLAT") )
		! print *,"Entro a Attributos de variable",dimids,id,jd
	  return
	  end subroutine crea_attr2
!
! M      M EEEEE  SSSS
! M M  M M E     S
! M  M   M EEE    SSS
! M      M E         S
! M      M EEEEE SSSS
         character(len=3)function mes(num)
          character*2 num
          select case (num)
            case('01')
              mes='Jan'
             case('02')
             mes='Feb'
             case('03')
             mes='Mar'
             case('04')
             mes='Apr'
             case('05')
             mes='May'
             case('06')
             mes='Jun'
             case('07')
             mes='Jul'
             case('08')
             mes='Aug'
             case('09')
             mes='Sep'
             case('10')
             mes='Oct'
             case('11')
             mes='Nov'
             case('12')
             mes='Dec'
             end select
          return

          end function
!
end program guarda_nc