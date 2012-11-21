! THIS VERSION: CUTEST 1.0 - 19/11/2012 AT 13:15 GMT.

!-*-*-*-*-*-*-  C U T E S T    C N A M E S    S U B R O U T I N E  -*-*-*-*-*-

!  Copyright reserved, Gould/Orban/Toint, for GALAHAD productions
!  Principal author: Nick Gould

!  History -
!   fortran 77 version originally released in CUTE, September 1992
!   fortran 2003 version released in CUTEst, 19th November 2012

      SUBROUTINE UNAMES( data, status, n, pname, VNAME )
      USE CUTEST

!  Dummy arguments

      TYPE ( CUTEST_data_type ), INTENT( INOUT ) :: data
      INTEGER, INTENT( IN ) :: n
      INTEGER, INTENT( OUT ) :: status
      CHARACTER ( LEN = 10 ), INTENT( OUT ) :: pname
      CHARACTER ( LEN = 10 ), INTENT( OUT ), DIMENSION( n ) :: VNAME

!  -------------------------------------------------
!  Obtain the names of the problem and its variables
!  -------------------------------------------------

!  set the problem name

      pname = data%pname

!  set the names of the variables

      VNAME( : n ) = data%VNAMES( : n )
      status = 0
      RETURN

!  end of subroutine UNAMES

      END SUBROUTINE UNAMES
