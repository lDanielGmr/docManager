package clasesGenericas;

import ConexionBD.conexionBD;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public class Metadata {
    
    public static List<Map<String,Object>> findCommonTags() throws SQLException {
        String sql =
            "SELECT e.nombre, COUNT(*) AS cnt " +
            "FROM etiqueta e " +
            "JOIN docu_etiqueta de ON e.id = de.etq_id " +
            "GROUP BY e.nombre " +
            "ORDER BY cnt DESC " +
            "LIMIT 10";
        List<Map<String,Object>> tags = new ArrayList<>();
        try (Connection c = conexionBD.conectar();
             PreparedStatement ps = c.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            while (rs.next()) {
                Map<String,Object> row = new HashMap<>();
                row.put("nombre", rs.getString("nombre"));
                row.put("cnt", rs.getInt("cnt"));
                tags.add(row);
            }
        }
        return tags;
    }
    
    public static List<Map<String, Object>> findCommonTagsByUser(int userId) throws SQLException {
        String sql =
            "SELECT e.nombre, COUNT(*) AS cnt " +
            "FROM etiqueta e " +
            "JOIN docu_etiqueta de ON e.id = de.etq_id " +
            "JOIN documento d ON de.doc_id = d.id " +
            "WHERE (d.recibido_por = ? OR d.radicado_a = ?) " +
            "  AND d.eliminado = 0 " +
            "GROUP BY e.nombre " +
            "ORDER BY cnt DESC " +
            "LIMIT 10";

        List<Map<String, Object>> tags = new ArrayList<>();
        try (Connection c = conexionBD.conectar();
             PreparedStatement ps = c.prepareStatement(sql)) {

            ps.setInt(1, userId);
            ps.setInt(2, userId);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    Map<String, Object> row = new HashMap<>();
                    row.put("nombre", rs.getString("nombre"));
                    row.put("cnt",    rs.getInt("cnt"));
                    tags.add(row);
                }
            }
        }
        return tags;
    }
}

