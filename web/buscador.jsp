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
    String field     = request.getParameter("field");

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

    try (Connection conn = conexionBD.conectar()) {

        if ("numeroRadicado".equalsIgnoreCase(field)) {
            String sql =
              "SELECT DISTINCT d.numero_radicado " +
              "FROM documento d " +
              "WHERE IFNULL(d.eliminado,0) = 0 " +
              "  AND d.numero_radicado COLLATE utf8mb4_unicode_ci LIKE ? " +
              "  AND (d.es_plantilla = 1 OR d.radicado_a = ? OR d.recibido_por = ?) " +
              "ORDER BY d.numero_radicado ASC " +
              "LIMIT 10";
            try (PreparedStatement pst = conn.prepareStatement(sql)) {
                pst.setString(1, term);
                pst.setInt(2, userId);
                pst.setInt(3, userId);
                try (ResultSet rs = pst.executeQuery()) {
                    while (rs.next()) {
                        String nr = rs.getString("numero_radicado");
                        if (nr != null) {
                            suggestions.add(nr);
                        }
                    }
                }
            }

        } else if ("etiqueta".equalsIgnoreCase(field)) {
            String sql =
              "SELECT DISTINCT e.nombre " +
              "FROM etiqueta e " +
              "JOIN docu_etiqueta de ON e.id = de.etq_id " +
              "JOIN documento d ON de.doc_id = d.id " +
              "WHERE IFNULL(d.eliminado,0) = 0 " +
              "  AND e.nombre COLLATE utf8mb4_unicode_ci LIKE ? " +
              "  AND (d.es_plantilla = 1 OR d.radicado_a = ? OR d.recibido_por = ?) " +
              "ORDER BY e.nombre ASC " +
              "LIMIT 10";
            try (PreparedStatement pst = conn.prepareStatement(sql)) {
                pst.setString(1, term);
                pst.setInt(2, userId);
                pst.setInt(3, userId);
                try (ResultSet rs = pst.executeQuery()) {
                    while (rs.next()) {
                        suggestions.add(rs.getString("nombre"));
                    }
                }
            }

        } else if ("tipo".equalsIgnoreCase(field)) {
            String sql =
              "SELECT DISTINCT d.tipo " +
              "FROM documento d " +
              "WHERE IFNULL(d.eliminado,0) = 0 " +
              "  AND d.tipo COLLATE utf8mb4_unicode_ci LIKE ? " +
              "  AND (d.es_plantilla = 1 OR d.radicado_a = ? OR d.recibido_por = ?) " +
              "ORDER BY d.tipo ASC " +
              "LIMIT 10";
            try (PreparedStatement pst = conn.prepareStatement(sql)) {
                pst.setString(1, term);
                pst.setInt(2, userId);
                pst.setInt(3, userId);
                try (ResultSet rs = pst.executeQuery()) {
                    while (rs.next()) {
                        suggestions.add(rs.getString("tipo"));
                    }
                }
            }

        } else {
            String sql =
              "SELECT DISTINCT d.titulo " +
              "FROM documento d " +
              "WHERE IFNULL(d.eliminado,0) = 0 " +
              "  AND d.titulo COLLATE utf8mb4_unicode_ci LIKE ? " +
              "  AND (d.es_plantilla = 1 OR d.radicado_a = ? OR d.recibido_por = ?) " +
              "ORDER BY d.titulo ASC " +
              "LIMIT 10";
            try (PreparedStatement pst = conn.prepareStatement(sql)) {
                pst.setString(1, term);
                pst.setInt(2, userId);
                pst.setInt(3, userId);
                try (ResultSet rs = pst.executeQuery()) {
                    while (rs.next()) {
                        suggestions.add(rs.getString("titulo"));
                    }
                }
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
