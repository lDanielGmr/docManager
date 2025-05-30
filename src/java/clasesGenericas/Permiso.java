package clasesGenericas;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;

import ConexionBD.conexionBD;

public class Permiso {
    private int id;
    private String nombre;
    private boolean requiereRespuesta;
    private boolean respondido;

    public Permiso() { }

    public Permiso(int id, String nombre, boolean requiereRespuesta, boolean respondido) {
        this.id = id;
        this.nombre = nombre;
        this.requiereRespuesta = requiereRespuesta;
        this.respondido = respondido;
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

    public boolean isRequiereRespuesta() {
        return requiereRespuesta;
    }

    public void setRequiereRespuesta(boolean requiereRespuesta) {
        this.requiereRespuesta = requiereRespuesta;
    }

    public boolean isRespondido() {
        return respondido;
    }

    public void setRespondido(boolean respondido) {
        this.respondido = respondido;
    }

    public static List<Permiso> findAll() {
        List<Permiso> lista = new ArrayList<>();
        String sql = "SELECT id, nombre, requiere_respuesta, respondido FROM permiso";
        try (Connection cn = conexionBD.conectar();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                lista.add(new Permiso(
                    rs.getInt("id"),
                    rs.getString("nombre"),
                    rs.getBoolean("requiere_respuesta"),
                    rs.getBoolean("respondido")
                ));
            }
        } catch (Exception ex) {
            ex.printStackTrace();
        }
        return lista;
    }

    public static Permiso findById(int idBuscado) {
        String sql = "SELECT id, nombre, requiere_respuesta, respondido FROM permiso WHERE id = ?";
        try (Connection cn = conexionBD.conectar();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, idBuscado);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return new Permiso(
                        rs.getInt("id"),
                        rs.getString("nombre"),
                        rs.getBoolean("requiere_respuesta"),
                        rs.getBoolean("respondido")
                    );
                }
            }
        } catch (Exception ex) {
            ex.printStackTrace();
        }
        return null;
    }

    public boolean save() {
        String sql = "INSERT INTO permiso(nombre, requiere_respuesta, respondido) VALUES(?, ?, ?)";
        try (Connection cn = conexionBD.conectar();
             PreparedStatement ps = cn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS)) {
            ps.setString(1, nombre);
            ps.setBoolean(2, requiereRespuesta);
            ps.setBoolean(3, respondido);
            if (ps.executeUpdate() == 1) {
                try (ResultSet rs = ps.getGeneratedKeys()) {
                    if (rs.next()) {
                        this.id = rs.getInt(1);
                    }
                }
                return true;
            }
        } catch (Exception ex) {
            ex.printStackTrace();
        }
        return false;
    }

    public boolean update() {
        String sql = "UPDATE permiso SET nombre = ?, requiere_respuesta = ?, respondido = ? WHERE id = ?";
        try (Connection cn = conexionBD.conectar();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, nombre);
            ps.setBoolean(2, requiereRespuesta);
            ps.setBoolean(3, respondido);
            ps.setInt(4, id);
            return ps.executeUpdate() == 1;
        } catch (Exception ex) {
            ex.printStackTrace();
        }
        return false;
    }

    public boolean delete() {
        String sql = "DELETE FROM permiso WHERE id = ?";
        try (Connection cn = conexionBD.conectar();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, id);
            return ps.executeUpdate() == 1;
        } catch (Exception ex) {
            ex.printStackTrace();
        }
        return false;
    }
}
