<%@ page contentType="text/html; charset=UTF-8" language="java" session="true" %>
<%@ page import="ConexionBD.conexionBD, java.sql.Connection, java.sql.PreparedStatement" %>
<%
    request.setCharacterEncoding("UTF-8");

    int rolId = Integer.parseInt(request.getParameter("rolId"));
    String[] permisosSel = request.getParameterValues("permisoId");

    try (Connection cn = conexionBD.conectar()) {
        try (PreparedStatement psDel =
                 cn.prepareStatement("DELETE FROM rol_permiso WHERE rol_id = ?")) {
            psDel.setInt(1, rolId);
            psDel.executeUpdate();
        }
        if (permisosSel != null) {
            try (PreparedStatement psIns =
                     cn.prepareStatement("INSERT INTO rol_permiso(rol_id, permiso_id) VALUES(?,?)")) {
                for (String pid : permisosSel) {
                    psIns.setInt(1, rolId);
                    psIns.setInt(2, Integer.parseInt(pid));
                    psIns.addBatch();
                }
                psIns.executeBatch();
            }
        }
    } catch (Exception e) {
        e.printStackTrace();
    }

    String contexto = request.getContextPath();
    response.sendRedirect(contexto + "/permiso.jsp");
%>
