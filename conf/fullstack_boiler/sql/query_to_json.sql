SELECT
  coalesce(json_agg("root"), '[]') AS "root"
FROM
  (
    SELECT
      row_to_json(
        (
          SELECT
            "_7_e"
          FROM
            (
              SELECT
                "_0_root.base"."id" AS "id",
                "_0_root.base"."name" AS "name",
                "_0_root.base"."position" AS "position",
                "_0_root.base"."globalGrade" AS "globalGrade",
                "_0_root.base"."currency" AS "currency",
                "_0_root.base"."corporateFunction" AS "corporateFunction",
                "_0_root.base"."location" AS "location",
                "_0_root.base"."startDate" AS "startDate",
                "_0_root.base"."endDate" AS "endDate",
                "_0_root.base"."baseSalary" AS "baseSalary",
                "_0_root.base"."payoutCap" AS "payoutCap",
                "_0_root.base"."targetSTI" AS "targetSTI",
                "_0_root.base"."manager" AS "manager",
                "_0_root.base"."managersManager" AS "managersManager",
                "_0_root.base"."ecMember" AS "ecMember",
                "_0_root.base"."hasApprovedPlan" AS "hasApprovedPlan",
                "_0_root.base"."localID" AS "localID",
                "_3_root.or.country"."country" AS "country",
                "_6_root.or.unit"."unit" AS "unit"
            ) AS "_7_e"
        )
      ) AS "root"
    FROM
      (
        SELECT
          *
        FROM
          "public"."colleague"
        WHERE
          ('true')
      ) AS "_0_root.base"
      LEFT OUTER JOIN LATERAL (
        SELECT
          row_to_json(
            (
              SELECT
                "_2_e"
              FROM
                (
                  SELECT
                    "_1_root.or.country.base"."id" AS "id",
                    "_1_root.or.country.base"."countryName" AS "countryName"
                ) AS "_2_e"
            )
          ) AS "country"
        FROM
          (
            SELECT
              *
            FROM
              "public"."country"
            WHERE
              (("_0_root.base"."countryId") = ("id"))
          ) AS "_1_root.or.country.base"
      ) AS "_3_root.or.country" ON ('true')
      LEFT OUTER JOIN LATERAL (
        SELECT
          row_to_json(
            (
              SELECT
                "_5_e"
              FROM
                (
                  SELECT
                    "_4_root.or.unit.base"."currency" AS "currency",
                    "_4_root.or.unit.base"."size" AS "size",
                    "_4_root.or.unit.base"."financialType" AS "financialType",
                    "_4_root.or.unit.base"."profit" AS "profit",
                    "_4_root.or.unit.base"."revenue" AS "revenue",
                    "_4_root.or.unit.base"."profitMargin" AS "profitMargin",
                    "_4_root.or.unit.base"."dso" AS "dso",
                    "_4_root.or.unit.base"."revenueQ1" AS "revenueQ1",
                    "_4_root.or.unit.base"."profitMarginQ1" AS "profitMarginQ1",
                    "_4_root.or.unit.base"."revenueQ2" AS "revenueQ2",
                    "_4_root.or.unit.base"."profitMarginQ2" AS "profitMarginQ2",
                    "_4_root.or.unit.base"."revenueQ3" AS "revenueQ3",
                    "_4_root.or.unit.base"."profitMarginQ3" AS "profitMarginQ3",
                    "_4_root.or.unit.base"."revenueQ4" AS "revenueQ4",
                    "_4_root.or.unit.base"."profitMarginQ4" AS "profitMarginQ4",
                    "_4_root.or.unit.base"."isLocked" AS "isLocked"
                ) AS "_5_e"
            )
          ) AS "unit"
        FROM
          (
            SELECT
              *
            FROM
              "public"."unit"
            WHERE
              (("_0_root.base"."unit4Id") = ("id"))
          ) AS "_4_root.or.unit.base"
      ) AS "_6_root.or.unit" ON ('true')
  ) AS "_8_root";
