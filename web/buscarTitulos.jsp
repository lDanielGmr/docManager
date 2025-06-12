<%@ page contentType="application/json; charset=UTF-8" language="java" %>
<%@ page import="
    java.util.Optional,
    java.sql.Connection,
    java.sql.PreparedStatement,
    java.sql.ResultSet,
    java.util.ArrayList,
    java.util.HashMap,
    java.util.List,
    java.util.Map,
    javax.servlet.http.HttpServletResponse,
    ConexionBD.conexionBD,
    com.google.gson.Gson
" %>
<%
    String term = Optional.ofNullable(request.getParameter("term")).orElse("").trim();
    boolean exact = "true".equalsIgnoreCase(request.getParameter("exact"));
    String scope = Optional.ofNullable(request.getParameter("scope")).orElse("documento"); 
    String operador = exact ? "= ?" : "LIKE ?";
    String sqlTerm = exact ? term : "%" + term + "%";

    String wherePlantilla = "d.es_plantilla = " + ("plantilla".equals(scope) ? "TRUE" : "FALSE");

    String sql =
      "SELECT d.id, d.titulo, d.tipo, a.nombre AS area, u.nombre AS usuarioNombre, " +
      "       DATE(d.fecha_creacion) AS fechaCreacion, d.es_plantilla " +
      "FROM documento d " +
      "LEFT JOIN area a ON d.id_area = a.id " +
      "LEFT JOIN usuario u ON d.recibido_por = u.id " +
      "WHERE d.eliminado = 0 " +
      "  AND " + wherePlantilla + " " +
      (term.isEmpty() ? "" : "AND d.titulo " + operador + " ") +
      "ORDER BY d.fecha_creacion DESC " +
      "LIMIT 1000";

    List<Map<String,Object>> resultados = new ArrayList<>();
    try (Connection conn = conexionBD.conectar();
         PreparedStatement ps = conn.prepareStatement(sql)) {

        int idx = 1;
        if (!term.isEmpty()) {
            ps.setString(idx++, sqlTerm);
        }

        try (ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Map<String,Object> m = new HashMap<>();
                m.put("id",            rs.getInt("id"));
                m.put("titulo",        rs.getString("titulo"));
                m.put("tipo",          rs.getString("tipo"));
                m.put("area",          rs.getString("area"));
                m.put("usuarioNombre", rs.getString("usuarioNombre"));
                m.put("fechaCreacion", rs.getString("fechaCreacion"));
                m.put("esPlantilla",   rs.getBoolean("es_plantilla"));
                resultados.add(m);
            }
        }
    } catch (Exception e) {
        response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
        resultados.clear();
    }

    response.setStatus(HttpServletResponse.SC_OK);
    out.print(new Gson().toJson(resultados));
    out.flush();
%>
