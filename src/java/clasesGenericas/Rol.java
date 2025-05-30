package clasesGenericas;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;

import ConexionBD.conexionBD;

public class Rol {
    private int id;
    private String nombre;

    public Rol() { }

    public Rol(int id, String nombre) {
        this.id     = id;
        this.nombre = nombre;
    }

    public int getId() { return id; }
    public void setId(int id) { this.id = id; }
    public String getNombre() { return nombre; }
    public void setNombre(String nombre) { this.nombre = nombre; }


    public static List<Rol> findAll() {
        List<Rol> lista = new ArrayList<>();
        String sql = "SELECT id, nombre FROM rol";
        try (Connection cn = conexionBD.conectar();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                lista.add(new Rol(rs.getInt("id"), rs.getString("nombre")));
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return lista;
    }

    public static Rol findById(int idBuscado) {
        String sql = "SELECT id, nombre FROM rol WHERE id = ?";
        try (Connection cn = conexionBD.conectar();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, idBuscado);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return new Rol(rs.getInt("id"), rs.getString("nombre"));
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return null;
    }

    public static Rol findByUsuario(String username) {
        String sql = "SELECT r.id, r.nombre " +
                     "FROM rol r " +
                     "JOIN usuario u ON u.id_rol = r.id " +
                     "WHERE u.usuario = ?";
        try (Connection cn = conexionBD.conectar();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, username);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return new Rol(rs.getInt("id"), rs.getString("nombre"));
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return null;
    }

    public boolean save() {
        String sql = "INSERT INTO rol(nombre) VALUES(?)";
        try (Connection cn = conexionBD.conectar();
             PreparedStatement ps = cn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setString(1, nombre);
            if (ps.executeUpdate() == 1) {
                try (ResultSet rs = ps.getGeneratedKeys()) {
                    if (rs.next()) {
                        this.id = rs.getInt(1);
                    }
                }
                return true;
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }

    public boolean update() {
        String sql = "UPDATE rol SET nombre = ? WHERE id = ?";
        try (Connection cn = conexionBD.conectar();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, nombre);
            ps.setInt(2, id);
            return ps.executeUpdate() == 1;
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }

    public boolean delete() {
        String sql = "DELETE FROM rol WHERE id = ?";
        try (Connection cn = conexionBD.conectar();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, id);
            return ps.executeUpdate() == 1;
        } catch (Exception e) {
            e.printStackTrace();
        }
        return false;
    }
}
