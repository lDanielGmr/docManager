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
}
