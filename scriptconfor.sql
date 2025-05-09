USE [BD_TICAGestionCambio]
GO
/****** Object:  StoredProcedure [dbo].[que_LILicencia_Listar]    Script Date: 24/03/2025 10:49:12 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[que_LILicencia_Listar]
    @PageNumber INT, -- Número de página
    @PageSize INT = 15 -- Registros por página (15 por defecto)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @TotalRegistros INT;
    DECLARE @TotalPaginas INT;

    -- Calcular el total de registros
    SELECT @TotalRegistros = COUNT(*)
    FROM LILicencia WHERE chActivo = 'S';

    -- Calcular el total de páginas
    SET @TotalPaginas = CEILING(CAST(@TotalRegistros AS FLOAT) / @PageSize);

    -- Consulta principal con paginación
    WITH CTE_LICENCIAS AS (
        SELECT
            CAST(L.inLicencia AS VARCHAR) AS inLicencia,
            CASE 
                WHEN L.inTipoConformidad = 1 THEN 'Ord. Servicio' + CHAR(13) + CHAR(10) + 'N° ' + CAST(L.inNumOrden AS VARCHAR)
                WHEN L.inTipoConformidad = 2 THEN 'Ord. Compra' + CHAR(13) + CHAR(10) + 'N° ' + CAST(L.inNumOrden AS VARCHAR)
            END AS vcConformidad,
			CASE 
                WHEN L.inTipoConformidad = 1 THEN 'HES' 
                WHEN L.inTipoConformidad = 2 THEN 'HEE'
            END AS vcTipo,
            P.vcRazonSocial,
            FORMAT(L.dtFechaConformidad, 'dd/MM/yyyy') AS vcFecha,
            CONCAT(PER.VCPRIMERNOMBRE, ' ', PER.VCAPELLIDOPATERNO) AS vcUsuarioRegistro,
            'I: ' + FORMAT(L.dtPeriodoInicio, 'dd/MM/yyyy') + CHAR(13) + CHAR(10) +  'T: ' + FORMAT(L.dtPeriodoFin, 'dd/MM/yyyy') AS vcPeriodo,
            CASE 
                WHEN L.inTipoMoneda = 3 THEN 'S/ ' + FORMAT(L.deMonto, 'N2')
                WHEN L.inTipoMoneda = 4 THEN '$ ' + FORMAT(L.deMonto, 'N2')
                ELSE FORMAT(L.deMonto, 'N2')
            END AS deMonto,
			L.dtRegistro,
			L.vbConformidadF,
			L.vcConformidadF,
			P.vcNumeroNIF as ruc,
            ROW_NUMBER() OVER (PARTITION BY L.inLicencia ORDER BY L.inLicencia DESC) AS fila
        FROM LILicencia L
        LEFT JOIN [BD_Proveedor].[dbo].[PROVEEDOR] P ON L.inProveedor = P.inProveedor
        LEFT JOIN [BD_Personal].[dbo].[Personal] PER ON L.inPersonalRegistro = PER.kInPersonal
        WHERE L.chActivo = 'S' 
    )
    SELECT 
        inLicencia,
        vcConformidad,
        vcTipo,
        vcRazonSocial,
        vcFecha,
        vcUsuarioRegistro,
        vcPeriodo,
        deMonto,
        @TotalPaginas AS inTotalPaginas,
		dtRegistro ,
		vbConformidadF,
		vcConformidadF,
		ruc
    FROM CTE_LICENCIAS
    WHERE fila = 1
    ORDER BY inLicencia   DESC
    OFFSET (@PageNumber - 1) * @PageSize ROWS
    FETCH NEXT @PageSize ROWS ONLY;
END;
GO
