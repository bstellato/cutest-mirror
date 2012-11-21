! ( Last modified on 23 Dec 2000 at 22:01:38 )
      SUBROUTINE UPROD( data, status, n, goth, X, P, RESULT )
      USE CUTEST
      TYPE ( CUTEST_data_type ) :: data
      INTEGER, PARAMETER :: wp = KIND( 1.0D+0 )
      INTEGER :: n
      INTEGER, INTENT( OUT ) :: status
      LOGICAL :: goth
      REAL ( KIND = wp ) :: X( n ), P( n ), RESULT( n )

!  Compute the matrix-vector product between the Hessian matrix
!  of a group partially separable function and a given vector P.
!  The result is placed in RESULT. If goth is .TRUE. the second
!  derivatives are assumed to have already been computed. If
!  the user is unsure, set goth = .FALSE. the first time a product
!  is required with the Hessian evaluated at X. X is not used if
!  goth = .TRUE.

!  Based on the minimization subroutine data%laNCELOT/SBMIN
!  by Conn, Gould and Toint.

!  Nick Gould, for CGT productions.
!  July, 1991.

!  integer variables from the PRFCTS common block.

!  Local variables

      INTEGER :: i, ig, j, nn, nbprod, nnonnz, ifstat, igstat
      INTEGER :: lnwk, lnwkb, lnwkc, lwkb, lwkc
      REAL ( KIND = wp ) :: ftt
      EXTERNAL :: RANGE 

!  There are non-trivial group functions.

      IF ( .NOT. goth ) THEN
         DO i = 1, MAX( data%nel, data%ng )
           data%ICALCF( i ) = i
         END DO

!  evaluate the element function values

        CALL ELFUN( data%FUVALS, X, data%EPVALU, data%nel, data%ITYPEE,        &
                    data%ISTAEV, data%IELVAR, data%INTVAR, data%ISTADH,        &
                    data%ISTEP, data%ICALCF, data%ltypee, data%lstaev,         &
                    data%lelvar, data%lntvar, data%lstadh, data%lstep,         &
                    data%lcalcf, data%lfuval, data%lvscal, data%lepvlu,        &
                    1, ifstat )

!  evaluate the element function gradient and Hessian values

        CALL ELFUN( data%FUVALS, X, data%EPVALU, data%nel, data%ITYPEE,        &
                    data%ISTAEV, data%IELVAR, data%INTVAR, data%ISTADH,        &
                    data%ISTEP, data%ICALCF, data%ltypee, data%lstaev,         &
                    data%lelvar, data%lntvar, data%lstadh, data%lstep,         &
                    data%lcalcf, data%lfuval, data%lvscal, data%lepvlu,        &
                    3, ifstat )

!  compute the group argument values ft

         DO ig = 1, data%ng
           ftt = - data%B( ig )

!  include the contribution from the linear element

           DO j = data%ISTADA( ig ), data%ISTADA( ig + 1 ) - 1
             ftt = ftt + data%A( j ) * X( data%ICNA( j ) )
           END DO

!  include the contributions from the nonlinear elements

           DO j = data%ISTADG( ig ), data%ISTADG( ig + 1 ) - 1
              ftt = ftt + data%ESCALE( j ) * data%FUVALS( data%IELING( J))
           END DO
           data%FT( ig ) = ftt

!  record the derivatives of trivial groups

           IF ( data%GXEQX( ig ) ) THEN
              data%GVALS( ig, 2 ) = 1.0_wp
              data%GVALS( ig, 3 ) = 0.0_wp
           END IF
        END DO

!  evaluate the group derivative values

        IF ( .NOT. data%altriv )                                               &
          CALL GROUP( data%GVALS, data%ng, data%FT, data%GPVALU, data%ng,      &
                      data%ITYPEG, data%ISTGP, data%ICALCF, data%ltypeg,       &
                      data%lstgp, data%lcalcf, data%lcalcg, data%lgpvlu,       &
                      .TRUE., igstat )

!  compute the gradient value

        CALL ELGRD( n, data%ng, data%firstg, data%ICNA( 1 ), data%licna, &
                      data%ISTADA( 1 ), data%lstada, data%IELING( 1 ), &
                      data%leling, data%ISTADG( 1 ), data%lstadg, &
                      data%ITYPEE( 1 ), data%lintre, &
                      data%ISTAEV( 1 ), data%lstaev, data%IELVAR( 1 ), &
                      data%lelvar, data%INTVAR( 1 ), data%lntvar, &
                      data%IWORK( data%lsvgrp + 1 ), &
                      data%lnvgrp, data%IWORK( data%lstajc + 1 ), &
                      data%lnstjc, data%IWORK( data%lstagv + 1 ), data%lnstgv, &
                      data%A( 1 ), data%la, data%GVALS( : , 2 ), data%lgvals, &
                      data%FUVALS, data%lnguvl, data%FUVALS( data%lggfx + 1 ), &
                      data%GSCALE( 1 ), data%lgscal, &
                      data%ESCALE( 1 ), data%lescal, &
                      data%FUVALS( data%lgrjac + 1 ), &
                      data%lngrjc, data%WRK( 1 ), data%WRK( n + 1 ), &
                      data%maxsel, data%GXEQX( 1 ), data%lgxeqx, &
                      data%INTREP( 1 ), data%lintre, RANGE )
        data%firstg = .FALSE.
      END IF

!  ensure that the product involves all components of P

      DO i = 1, n
        data%IVAR( i ) = i
        data%IWORK( data%lnnonz + i ) = i
      END DO

!  initialize RESULT as the zero vector

      RESULT( : n ) = 0.0_wp

!  define the real work space needed for HSPRD. Ensure that there is 
!  sufficient space

      nn = data%ninvar + n
      lnwk = MAX( data%ng, data%maxsel )
      lnwkb = data%maxsin
      lnwkc = data%maxsin
      lwkb = lnwk
      lwkc = lwkb + lnwkb

!  evaluate the product

      CALL DHSPRD( n, nn, data%ng, data%ntotel, n, 1, n, nbprod, data%nel == 0, &
          data%IVAR( 1 ), data%ISTAEV( 1 ), data%lstaev, &
          data%ISTADH( 1 ), data%lstadh, data%INTVAR( 1 ), &
          data%lntvar, data%IELING( 1 ), data%leling, data%IELVAR( 1 ), &
          data%lelvar, data%IWORK( data%lstajc + 1 ), data%lnstjc, data%IWORK( data%lselts + 1 ), &
          data%lnelts, data%IWORK( data%lsptrs + 1 ), data%lnptrs, data%IWORK( data%lgcolj + 1 ),  &
          data%lngclj, data%IWORK( data%lslgrp + 1 ), data%lnlgrp, data%IWORK( data%lswksp + 1 ),  &
          data%lnwksp, data%IWORK( data%lsvgrp + 1 ), data%lnvgrp, data%IWORK( data%lstagv + 1 ), &
          data%lnstgv, data%IWORK( data%lvaljr + 1 ), data%lnvljr, data%ITYPEE( 1 ),  &
          data%lintre, nnonnz, data%IWORK( data%lnnonz + 1 ), data%lnnnon, &
          data%IWORK( data%liused + 1 ), data%lniuse, data%IWORK( data%lnonz2 + 1 ), &
          data%lnnno2, data%IWORK( data%lsymmh + 1 ), data%maxsin, P, RESULT, &
          data%GVALS( : , 2 ), data%GVALS( : , 3 ), &
          data%FUVALS( data%lgrjac + 1 ), data%lngrjc, data%GSCALE( 1 ), &
          data%ESCALE( 1 ), data%lescal, data%FUVALS, data%lnhuvl, &
          data%WRK( 1 ), lnwk, data%WRK( lwkb + 1 ), &
          lnwkb, data%WRK( lwkc + 1 ), lnwkc, &
          data%GXEQX( 1 ), data%lgxeqx, data%INTREP( 1 ), &
          data%lintre, .TRUE., RANGE )

!  update the counters for the report tool

      data%nhvpr = data%nhvpr + 1
      IF ( .NOT. GOTH ) THEN
         data%nc2oh = data%nc2oh + 1
      END IF
      status = 0
      RETURN

!  end of UPROD

      END


