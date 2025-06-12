<%@ page import="java.io.PrintWriter"%>
<%@ page import="java.util.List"%>
<%@ page contentType="application/json; charset=UTF-8" language="java" %>
<%@ page import="
    java.sql.Connection,
    java.sql.PreparedStatement,
    java.sql.ResultSet,
    java.util.ArrayList,
    java.util.HashMap,
    java.util.List,
    java.util.Map,
    ConexionBD.conexionBD
" %>

<%
    String term = request.getParameter("term");
    if (term == null) {
        term = "";
    }
    term = term.trim();

    String sqlTerm = "%" + term + "%";

    List<Map<String, Object>> resultados = new ArrayList<>();

    String sql =
      "SELECT d.titulo " +
      "FROM documento d " +
      "WHERE IFNULL(d.eliminado, 0) = 0 " +  
      "  AND d.titulo LIKE ? " +
      "ORDER BY d.titulo ASC " +
      "LIMIT 10";

    try (Connection conn = conexionBD.conectar();
         PreparedStatement ps = conn.prepareStatement(sql)) {

        ps.setString(1, sqlTerm);

        try (ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                String titulo = rs.getString("titulo");
                Map<String, Object> doc = new HashMap<>();
                doc.put("titulo", titulo);
                resultados.add(doc);
            }
        }
    } catch (Exception e) {
        e.printStackTrace();
    }

    response.setContentType("application/json; charset=UTF-8");
    PrintWriter writer = response.getWriter();

    writer.print("[");
    for (int i = 0; i < resultados.size(); i++) {
        Map<String, Object> doc = resultados.get(i);
        String tituloEsc = doc.get("titulo").toString().replace("\"", "\\\"");
        writer.print("{\"titulo\": \"" + tituloEsc + "\"}");
        if (i < resultados.size() - 1) {
            writer.print(",");
        }
    }
    writer.print("]");
    writer.flush();
%>
