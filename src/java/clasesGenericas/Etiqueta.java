package clasesGenericas;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

import ConexionBD.conexionBD;
import clasesGenericas.DocuEtiqueta;

public class Etiqueta {
    private static final Logger LOGGER = Logger.getLogger(Etiqueta.class.getName());

    private int id;
    private String nombre;

    public Etiqueta() { }

    public Etiqueta(int id, String nombre) {
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

    public static List<Etiqueta> findAll() {
        List<Etiqueta> lista = new ArrayList<>();
        String sql = "SELECT id, nombre FROM etiqueta";
        try (Connection cn = conexionBD.conectar();
             PreparedStatement ps = cn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                lista.add(new Etiqueta(
                    rs.getInt("id"),
                    rs.getString("nombre")
                ));
            }
        } catch (SQLException ex) {
            LOGGER.log(Level.SEVERE, "Error al obtener todas las etiquetas", ex);
        }
        return lista;
    }

    public static Etiqueta findById(int idBuscado) {
        String sql = "SELECT id, nombre FROM etiqueta WHERE id = ?";
        try (Connection cn = conexionBD.conectar();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, idBuscado);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return new Etiqueta(
                        rs.getInt("id"),
                        rs.getString("nombre")
                    );
                }
            }
        } catch (SQLException ex) {
            LOGGER.log(Level.SEVERE, "Error al buscar etiqueta por ID: " + idBuscado, ex);
        }
        return null;
    }

    public boolean save() {
        String sql = "INSERT INTO etiqueta(nombre) VALUES(?)";
        try (Connection cn = conexionBD.conectar();
             PreparedStatement ps = cn.prepareStatement(sql, PreparedStatement.RETURN_GENERATED_KEYS)) {
            ps.setString(1, nombre);
            int filas = ps.executeUpdate();
            if (filas == 1) {
                try (ResultSet rs = ps.getGeneratedKeys()) {
                    if (rs.next()) {
                        this.id = rs.getInt(1);
                    }
                }
                return true;
            } else {
                LOGGER.log(Level.WARNING, "No se insertó la etiqueta, filas afectadas: {0}", filas);
            }
        } catch (SQLException ex) {
            LOGGER.log(Level.SEVERE, "Error al insertar etiqueta: " + nombre, ex);
        }
        return false;
    }

    public boolean update() {
        String sql = "UPDATE etiqueta SET nombre = ? WHERE id = ?";
        try (Connection cn = conexionBD.conectar();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setString(1, nombre);
            ps.setInt(2, id);
            int filas = ps.executeUpdate();
            if (filas == 1) {
                return true;
            } else {
                LOGGER.log(Level.WARNING, "No se actualizó etiqueta con id={0}, filas afectadas: {1}", new Object[]{id, filas});
            }
        } catch (SQLException ex) {
            LOGGER.log(Level.SEVERE, "Error al actualizar etiqueta id=" + id, ex);
        }
        return false;
    }

    public boolean delete() {
        String sql = "DELETE FROM etiqueta WHERE id = ?";
        try (Connection cn = conexionBD.conectar();
             PreparedStatement ps = cn.prepareStatement(sql)) {
            ps.setInt(1, id);
            int filas = ps.executeUpdate();
            if (filas == 1) {
                return true;
            } else {
                LOGGER.log(Level.WARNING, "No se eliminó etiqueta id={0}, filas afectadas: {1}", new Object[]{id, filas});
            }
        } catch (SQLException ex) {
            if (ex instanceof java.sql.SQLIntegrityConstraintViolationException) {
                LOGGER.log(Level.WARNING, "No se puede eliminar etiqueta id={0}: está en uso (constraint).", id);
            } else {
                LOGGER.log(Level.SEVERE, "Error al eliminar etiqueta id=" + id, ex);
            }
        }
        return false;
    }

    public boolean isEnUso() {
        try {
            List<DocuEtiqueta> lista = DocuEtiqueta.findByEtqId(this.id);
            return lista != null && !lista.isEmpty();
        } catch (Exception ex) {
            LOGGER.log(Level.SEVERE, "Error al comprobar uso de etiqueta id=" + id + " vía DocuEtiqueta. Se asume no en uso.", ex);
            return false;
        }
    }
}
