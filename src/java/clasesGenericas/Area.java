package clasesGenericas;

import ConexionBD.conexionBD;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

public class Area {
    private int id;
    private String nombre;

    public Area() {}

    public Area(int id, String nombre) {
        this.id = id;
        this.nombre = nombre;
    }

    public int getId() {
        return id;
    }
    public void setId(int id) {
        this.id = id;
    }
    public String getNombre() {
        return nombre;
    }
    public void setNombre(String nombre) {
        this.nombre = nombre;
    }
    @Override
    public String toString() {
        return "Area{id=" + id + ", nombre='" + nombre + "'}";
    }

    private static Area mapRow(ResultSet rs) throws SQLException {
        Area a = new Area();
        a.setId(rs.getInt("id"));
        a.setNombre(rs.getString("nombre"));
        return a;
    }


    public static List<Area> findAll() throws SQLException {
        String sql = "SELECT id, nombre FROM area ORDER BY nombre";
        List<Area> list = new ArrayList<>();
        try (Connection c = conexionBD.conectar();
             PreparedStatement ps = c.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                list.add(mapRow(rs));
            }
        }
        return list;
    }


    public static Area findById(int id) throws SQLException {
        String sql = "SELECT id, nombre FROM area WHERE id = ?";
        try (Connection c = conexionBD.conectar();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return mapRow(rs);
                }
            }
        }
        return null;
    }

    public int save() throws SQLException {
        String sql = "INSERT INTO area (nombre) VALUES (?)";
        try (Connection c = conexionBD.conectar();
             PreparedStatement ps = c.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setString(1, this.nombre);
            ps.executeUpdate();
            try (ResultSet keys = ps.getGeneratedKeys()) {
                if (keys.next()) {
                    this.id = keys.getInt(1);
                }
            }
        }
        return this.id;
    }


    public void update() throws SQLException {
        String sql = "UPDATE area SET nombre = ? WHERE id = ?";
        try (Connection c = conexionBD.conectar();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, this.nombre);
            ps.setInt(2, this.id);
            ps.executeUpdate();
        }
    }


    public void delete() throws SQLException {
        String sql = "DELETE FROM area WHERE id = ?";
        try (Connection c = conexionBD.conectar();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, this.id);
            ps.executeUpdate();
        }
    }


    public static boolean isUsed(int id) {
        String sqlUsuario = "SELECT COUNT(*) FROM usuario WHERE id_area = ?";
        String sqlDocumento = "SELECT COUNT(*) FROM documento WHERE id_area = ?";
        try (Connection c = conexionBD.conectar()) {
            try (PreparedStatement ps1 = c.prepareStatement(sqlUsuario)) {
                ps1.setInt(1, id);
                try (ResultSet rs = ps1.executeQuery()) {
                    if (rs.next() && rs.getInt(1) > 0) {
                        return true;
                    }
                }
            }
            try (PreparedStatement ps2 = c.prepareStatement(sqlDocumento)) {
                ps2.setInt(1, id);
                try (ResultSet rs = ps2.executeQuery()) {
                    if (rs.next() && rs.getInt(1) > 0) {
                        return true;
                    }
                }
            }
            return false;
        } catch (SQLException ex) {
            ex.printStackTrace();
            return true;
        }
    }
}
