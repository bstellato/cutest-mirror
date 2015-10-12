!   ( Last modified on 6 Oct 2015 at 15:50:00 )

      PROGRAM RAL_NLLS_main
      USE ISO_C_BINDING
      USE NLLS_MODULE

!  RAL_NLLS test driver for problems derived from SIF files

!  Nick Gould, October 2015

      IMPLICIT NONE
      INTEGER :: status, i, m, n
      INTEGER( c_int ) :: len_work_integer, len_work_real
      REAL( c_double ), PARAMETER :: infty = 1.0D+19
      REAL( c_double ), DIMENSION( : ), ALLOCATABLE :: X, X_l, X_u
      REAL( c_double ), DIMENSION( : ), ALLOCATABLE :: Y, C_l, C_u, F
      REAL( c_double ), DIMENSION( : ), ALLOCATABLE ::  Work_real
      INTEGER( c_int ), DIMENSION( : ), ALLOCATABLE ::  Work_integer
      TYPE( NLLS_inform_type ) :: inform
      TYPE( NLLS_control_type ) :: control
      LOGICAL, DIMENSION( : ), ALLOCATABLE  :: EQUATN, LINEAR
      CHARACTER ( LEN = 10 ) :: pname
      CHARACTER ( LEN = 10 ), ALLOCATABLE, DIMENSION( : )  :: VNAMES, CNAMES
      REAL( c_double ), DIMENSION( 2 ) :: CPU
      REAL( c_double ), DIMENSION( 4 ) :: CALLS
      INTEGER :: io_buffer = 11
      INTEGER, PARAMETER :: input = 55, indr = 46, out = 6

!  Interface blocks

     INTERFACE
       SUBROUTINE eval_F( status, n, m, X, F )
         USE ISO_C_BINDING
         INTEGER ( c_int ), INTENT( OUT ) :: status
         INTEGER ( c_int ), INTENT( IN ) :: n, m
         REAL ( c_double ), DIMENSION( n ), INTENT( IN ) :: X
         REAL ( c_double ), DIMENSION( m ), INTENT( OUT ) :: F
       END SUBROUTINE eval_F
     END INTERFACE

     INTERFACE
       SUBROUTINE eval_J( status, n, m, X, J )
         USE ISO_C_BINDING
         INTEGER ( c_int ), INTENT( OUT ) :: status
         INTEGER ( c_int ), INTENT( IN ) :: n, m
         REAL ( c_double ), DIMENSION( n ), INTENT( IN ) :: X
         REAL ( c_double ), DIMENSION( m , n ), INTENT( OUT ) :: J
       END SUBROUTINE eval_J
     END INTERFACE

     INTERFACE
       SUBROUTINE eval_HF( status, n, m, X, F, H )
         USE ISO_C_BINDING
         INTEGER ( c_int ), INTENT( OUT ) :: status
         INTEGER ( c_int ), INTENT( IN ) :: n, m
         REAL ( c_double ), DIMENSION( n ), INTENT( IN ) :: X
         REAL ( c_double ), DIMENSION( m ), INTENT( IN ) :: F
         REAL ( c_double ), DIMENSION( n , n ), INTENT( OUT ) :: H
       END SUBROUTINE eval_HF
     END INTERFACE

!  open the relevant file

      OPEN( input, FILE = 'OUTSDIF.d', FORM = 'FORMATTED', STATUS = 'OLD' )
      REWIND( input )

!  compute problem dimensions

      CALL CUTEST_cdimen( status, input, n, m )
      IF ( status /= 0 ) GO TO 910

!  allocate space 

      ALLOCATE( X( n ), X_l( n ), X_u( n ), Y( m ), C_l( m ), C_u( m ),        &
                EQUATN( m ), LINEAR( m ), STAT = status )
      IF ( status /= 0 ) GO TO 990

!  initialize problem data structure

!  set up the data structures necessary to hold the problem functions.

      CALL CUTEST_csetup( status, input, out, io_buffer, n, m,                 &
                          X, X_l, X_u, Y, C_l, C_u, EQUATN, LINEAR, 0, 0, 0 )
      IF ( status /= 0 ) GO TO 910
      CLOSE( input )

!  allocate more space 

      DEALLOCATE( X_l, X_u, Y, C_l, C_u, EQUATN, LINEAR )
      len_work_integer = 0
      len_work_real = m + n * ( m + n )
      ALLOCATE( Work_integer( len_work_integer ), Work_real( len_work_real ),  &
                STAT = status )
      IF ( status /= 0 ) GO TO 990

!  open the Spec file for the method

      OPEN( indr, FILE = 'RAL_NLLS.SPC', FORM = 'FORMATTED', STATUS = 'OLD')
      REWIND( indr )

!  read input Spec data

!  error = unit for error messages
!  out = unit for information

!  set up algorithmic input data

      READ ( indr, 1000 ) control%error, control%out, control%print_level
      CLOSE ( indr )

!  call the minimizer

      CALL RAL_NLLS( n, m, X, Work_integer, len_work_integer, Work_real,       &
                     len_work_real, eval_F, eval_J, eval_HF,                   &
                     control, inform )
    
      IF ( status /= 0 ) GO TO 910

!  output report

      CALL CUTEST_ureport( status, CALLS, CPU )
      IF ( status /= 0 ) GO TO 910

      ALLOCATE( F( m ), VNAMES( n ), CNAMES( m ), STAT = status )
      CALL CUTEST_cnames( status, n, m, pname, VNAMES, CNAMES )
      CALL eval_F( status, n, m, X, F )

      WRITE( out, 2110 ) ( i, VNAMES( i ), X( i ), i = 1, n )
      WRITE( out, 2120 ) ( i, CNAMES( i ), F( i ), i = 1, m )
      WRITE( out, 2000 ) pname, n, CALLS( 1 ), inform%obj, CPU( 1 ), CPU( 2 )

!  clean-up data structures

      DEALLOCATE( X, F, VNAMES, CNAMES, Work_integer, Work_real,               &
                  STAT = status )
      IF ( status /= 0 ) GO TO 910
      CALL CUTEST_cterminate( status )
      STOP

!  error returns

  910 CONTINUE
      WRITE( 6, "( ' CUTEst error, status = ', i0, ', stopping' )") status
      STOP

  990 CONTINUE
      WRITE( out, "( ' Allocation error, status = ', I0 )" ) status
      STOP

!  Non-executable statements

2000 FORMAT( /, 24('*'), ' CUTEst statistics ', 24('*') //,                    &
          ' Package used            :  RAL_NLLS ',  /,                         &
          ' Problem                 :  ', A10,    /,                           &
          ' # variables             =      ', I10 /,                           &
          ' # residuals             =        ', F8.2 /,                        &
          ' Final f                 = ', E15.7 /,                              &
          ' Set up time             =      ', 0P, F10.2, ' seconds' /,         &
          ' Solve time              =      ', 0P, F10.2, ' seconds' //,        &
          66('*') / )
1000 FORMAT( I6, /, I6, /, I6 )
2110 FORMAT( /, ' The variables:', /, &
          '     i name          value',  /, ( I6, 1X, A10, 1P, D12.4 ) )
2120 FORMAT( /, ' The constraints:', /, '     i name          value',          &
          /, ( I6, 1X, A10, 1P, D12.4 ) )

!  End of RAL_NLLS_main

      END PROGRAM RAL_NLLS_main

      SUBROUTINE eval_F( status, n, m, X, F )
      USE ISO_C_BINDING
      INTEGER ( c_int ), INTENT( OUT ) :: status
      INTEGER ( c_int ), INTENT( IN ) :: n, m
      REAL ( c_double ), DIMENSION( n ), INTENT( IN ) :: X
      REAL ( c_double ), DIMENSION( m ), INTENT( OUT ) :: F
      REAL ( c_double ) :: obj

!  evaluate the residuals F

      CALL CUTEST_cfn( status, n, m, X, obj, F )
      RETURN
      END SUBROUTINE eval_F

      SUBROUTINE eval_J( status, n, m, X, J )
      USE ISO_C_BINDING
      INTEGER ( c_int ), INTENT( OUT ) :: status
      INTEGER ( c_int ), INTENT( IN ) :: n, m
      REAL ( c_double ), DIMENSION( n ), INTENT( IN ) :: X
      REAL ( c_double ), DIMENSION( m , n ), INTENT( OUT ) :: J
      REAL ( c_double ), DIMENSION( n ) :: G
      REAL ( c_double ), DIMENSION( m ) :: Y

!  evaluate the residual Jacobian J

      CALL CUTEST_cgr( status, n, m, X, Y, .FALSE., G, .FALSE., m, n, J )
      RETURN
      END SUBROUTINE eval_J

      SUBROUTINE eval_HF( status, n, m, X, F, H )
      USE ISO_C_BINDING
      INTEGER ( c_int ), INTENT( OUT ) :: status
      INTEGER ( c_int ), INTENT( IN ) :: n, m
      REAL ( c_double ), DIMENSION( n ), INTENT( IN ) :: X
      REAL ( c_double ), DIMENSION( m ), INTENT( IN ) :: F
      REAL ( c_double ), DIMENSION( n , n ), INTENT( OUT ) :: H

!  evaluate the product H = sum F_i Hessian F_i

      CALL CUTEST_cdhc( status, n, m, X, F, n, H )
      RETURN
      END SUBROUTINE eval_HF




