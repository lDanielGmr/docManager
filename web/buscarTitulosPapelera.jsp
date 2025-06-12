<%@ page contentType="application/json; charset=UTF-8" language="java" session="true" %>
<%@ page import="
    java.sql.Connection,
    java.sql.PreparedStatement,
    java.sql.ResultSet,
    java.util.ArrayList,
    java.util.List,
    clasesGenericas.Usuario,
    ConexionBD.conexionBD
" %>
<%
    String termParam = request.getParameter("term");
    if (termParam == null) {
        termParam = "";
    }
    termParam = termParam.trim();
    String term = "%" + termParam + "%";

    Usuario usuarioSesion = (Usuario) session.getAttribute("user");
    if (usuarioSesion == null) {
        out.write("[]");
        return;
    }
    int userId = usuarioSesion.getId();

    List<String> suggestions = new ArrayList<>();

    String sql =
      "SELECT DISTINCT d.titulo " +
      "FROM papelera p " +
      "JOIN documento d ON p.doc_id = d.id " +
      "WHERE d.eliminado = 1 " +
      "  AND (d.radicado_a = ? OR d.recibido_por = ?) " +
      "  AND d.titulo LIKE ? " +
      "ORDER BY d.titulo ASC " +
      "LIMIT 10";

    try (Connection conn = conexionBD.conectar();
         PreparedStatement pst = conn.prepareStatement(sql)) {

        pst.setInt(1, userId);
        pst.setInt(2, userId);
        pst.setString(3, term);

        try (ResultSet rs = pst.executeQuery()) {
            while (rs.next()) {
                suggestions.add(rs.getString("titulo"));
            }
        }
    } catch (Exception e) {
        e.printStackTrace();
    }

    StringBuilder json = new StringBuilder("[");
    for (int i = 0; i < suggestions.size(); i++) {
        String s = suggestions.get(i).replace("\"", "\\\"");
        json.append("\"").append(s).append("\"");
        if (i < suggestions.size() - 1) {
            json.append(",");
        }
    }
    json.append("]");

    out.write(json.toString());
%>
