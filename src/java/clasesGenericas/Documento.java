package clasesGenericas;

import ConexionBD.conexionBD;
import java.sql.*;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

public class Documento {
    private int id;
    private String titulo;
    private String tipo;
    private String numeroRadicado;             
    private Timestamp fechaCreacion;
    private boolean eliminado;
    private Integer recibidoPor;
    private Integer radicadoA;
    private boolean esPlantilla;
    private boolean requiereRespuesta;
    private boolean respondido;
    private String nombreArchivo;
    private Integer idArea;
    private String areaNombre;
    private List<Integer> etiquetaIds = new ArrayList<>();

    public Documento() {}

    public int getId() { return id; }
    public void setId(int id) { this.id = id; }

    public String getTitulo() { return titulo; }
    public void setTitulo(String titulo) { this.titulo = titulo; }

    public String getTipo() { return tipo; }
    public void setTipo(String tipo) { this.tipo = tipo; }

    public String getNumeroRadicado() { return numeroRadicado; }
    public void setNumeroRadicado(String numeroRadicado) { this.numeroRadicado = numeroRadicado; }

    public Timestamp getFechaCreacion() { return fechaCreacion; }
    public void setFechaCreacion(Timestamp fechaCreacion) { this.fechaCreacion = fechaCreacion; }

    public boolean isEliminado() { return eliminado; }
    public void setEliminado(boolean eliminado) { this.eliminado = eliminado; }

    public Integer getRecibidoPor() { return recibidoPor; }
    public void setRecibidoPor(Integer recibidoPor) { this.recibidoPor = recibidoPor; }

    public Integer getRadicadoA() { return radicadoA; }
    public void setRadicadoA(Integer radicadoA) { this.radicadoA = radicadoA; }

    public boolean isEsPlantilla() { return esPlantilla; }
    public void setEsPlantilla(boolean esPlantilla) { this.esPlantilla = esPlantilla; }

    public boolean isRequiereRespuesta() { return requiereRespuesta; }
    public void setRequiereRespuesta(boolean requiereRespuesta) { this.requiereRespuesta = requiereRespuesta; }

    public boolean isRespondido() { return respondido; }
    public void setRespondido(boolean respondido) { this.respondido = respondido; }

    public String getNombreArchivo() { return nombreArchivo; }
    public void setNombreArchivo(String nombreArchivo) { this.nombreArchivo = nombreArchivo; }

    public Integer getIdArea() { return idArea; }
    public void setIdArea(Integer idArea) { this.idArea = idArea; }

    public String getAreaNombre() { return areaNombre; }
    public void setAreaNombre(String areaNombre) { this.areaNombre = areaNombre; }

    public List<Integer> getEtiquetaIds() { return etiquetaIds; }

    public static int countAll() throws SQLException {
        try (Connection c = conexionBD.conectar();
             Statement st = c.createStatement();
             ResultSet rs = st.executeQuery("SELECT COUNT(*) FROM documento")) {
            return rs.next() ? rs.getInt(1) : 0;
        }
    }

    public static int countRequireResponse() throws SQLException {
        try (Connection c = conexionBD.conectar();
             Statement st = c.createStatement();
             ResultSet rs = st.executeQuery(
                 "SELECT COUNT(*) FROM documento WHERE requiere_respuesta = TRUE"
             )) {
            return rs.next() ? rs.getInt(1) : 0;
        }
    }

    public static Documento findById(int id) throws SQLException {
        String sql =
          "SELECT d.id, d.titulo, d.tipo, d.numero_radicado, d.fecha_creacion, d.eliminado, " +
          "       d.recibido_por, d.radicado_a, d.es_plantilla, d.requiere_respuesta, " +
          "       d.respondido, d.nombre_archivo, d.id_area, a.nombre AS area_nombre " +
          "  FROM documento d " +
          "  LEFT JOIN area a ON d.id_area = a.id " +
          " WHERE d.id = ?";
        try (Connection c = conexionBD.conectar();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, id);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) return null;
                Documento d = mapRow(rs);
                try (PreparedStatement ps2 = c.prepareStatement(
                         "SELECT etq_id FROM docu_etiqueta WHERE doc_id = ?")) {
                    ps2.setInt(1, id);
                    try (ResultSet rs2 = ps2.executeQuery()) {
                        while (rs2.next()) {
                            d.etiquetaIds.add(rs2.getInt("etq_id"));
                        }
                    }
                }
                return d;
            }
        }
    }

    public static List<Documento> findRequireResponse(int offset, int limit) throws SQLException {
        String sql =
          "SELECT d.id, d.titulo, d.tipo, d.numero_radicado, d.id_area, d.recibido_por, d.radicado_a, " +
          "       d.fecha_creacion, d.eliminado, d.es_plantilla, d.requiere_respuesta, d.respondido, " +
          "       a.nombre AS area_nombre " +
          "  FROM documento d " +
          "  LEFT JOIN area a ON d.id_area = a.id " +
          " WHERE d.requiere_respuesta = TRUE " +
          " ORDER BY d.fecha_creacion DESC " +
          " LIMIT ? OFFSET ?";
        List<Documento> list = new ArrayList<>();
        try (Connection c = conexionBD.conectar();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, limit);
            ps.setInt(2, offset);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(mapRow(rs));
                }
            }
        }
        return list;
    }

    public static List<Documento> findAllPlantillas() throws SQLException {
        String sql =
          "SELECT d.id, d.titulo, d.tipo, d.numero_radicado, d.id_area, d.recibido_por, d.radicado_a, " +
          "       d.fecha_creacion, d.eliminado, d.es_plantilla, d.requiere_respuesta, d.respondido, " +
          "       a.nombre AS area_nombre " +
          "  FROM documento d " +
          "  LEFT JOIN area a ON d.id_area = a.id " +
          " WHERE d.es_plantilla = TRUE " +
          " ORDER BY d.fecha_creacion DESC";
        List<Documento> list = new ArrayList<>();
        try (Connection c = conexionBD.conectar();
             PreparedStatement ps = c.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) list.add(mapRow(rs));
        }
        return list;
    }

    public static List<Documento> findAll() throws SQLException {
        String sql =
          "SELECT d.id, d.titulo, d.tipo, d.numero_radicado, d.id_area, d.recibido_por, d.radicado_a, " +
          "       d.fecha_creacion, d.eliminado, d.es_plantilla, d.requiere_respuesta, d.respondido, " +
          "       a.nombre AS area_nombre " +
          "  FROM documento d " +
          "  LEFT JOIN area a ON d.id_area = a.id " +
          " ORDER BY d.fecha_creacion DESC";
        List<Documento> list = new ArrayList<>();
        try (Connection c = conexionBD.conectar();
             PreparedStatement ps = c.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) list.add(mapRow(rs));
        }
        return list;
    }

    public void save(List<Integer> etiquetasIds) throws SQLException {
        String insertDoc =
          "INSERT INTO documento (" +
          " titulo, tipo, numero_radicado, id_area, es_plantilla, recibido_por, radicado_a, requiere_respuesta, respondido, nombre_archivo" +
          ") VALUES (?,?,?,?,?,?,?,?,?,?)";
        try (Connection c = conexionBD.conectar();
             PreparedStatement ps = c.prepareStatement(insertDoc, Statement.RETURN_GENERATED_KEYS)) {
            ps.setString(1, this.titulo);
            ps.setString(2, this.tipo);
            ps.setString(3, this.numeroRadicado);
            ps.setObject(4, this.idArea, Types.INTEGER);
            ps.setBoolean(5, this.esPlantilla);
            ps.setObject(6, this.recibidoPor, Types.INTEGER);
            ps.setObject(7, this.radicadoA, Types.INTEGER);
            ps.setBoolean(8, this.requiereRespuesta);
            ps.setBoolean(9, this.respondido);
            ps.setString(10, this.nombreArchivo);
            ps.executeUpdate();
            try (ResultSet keys = ps.getGeneratedKeys()) {
                if (keys.next()) this.id = keys.getInt(1);
                else throw new SQLException("No se generó ID para el documento.");
            }
        }
        insertarEtiquetas(etiquetasIds);
    }

    private void insertarEtiquetas(List<Integer> etiquetasIds) throws SQLException {
        if (etiquetasIds == null || etiquetasIds.isEmpty()) return;
        try (Connection c = conexionBD.conectar();
             PreparedStatement ps = c.prepareStatement(
                 "INSERT INTO docu_etiqueta(doc_id, etq_id) VALUES(?,?)")) {
            for (Integer etqId : etiquetasIds) {
                ps.setInt(1, this.id);
                ps.setInt(2, etqId);
                ps.addBatch();
            }
            ps.executeBatch();
        }
    }

    private static Documento mapRow(ResultSet rs) throws SQLException {
        Documento d = new Documento();
        d.setId(rs.getInt("id"));
        d.setTitulo(rs.getString("titulo"));
        d.setTipo(rs.getString("tipo"));
        d.setNumeroRadicado(rs.getString("numero_radicado"));
        d.setFechaCreacion(rs.getTimestamp("fecha_creacion"));
        d.setEliminado(rs.getBoolean("eliminado"));
        d.setRecibidoPor((Integer)rs.getObject("recibido_por"));
        d.setRadicadoA((Integer)rs.getObject("radicado_a"));
        d.setEsPlantilla(rs.getBoolean("es_plantilla"));
        d.setRequiereRespuesta(rs.getBoolean("requiere_respuesta"));
        d.setRespondido(rs.getBoolean("respondido"));
        d.setNombreArchivo(rs.getString("nombre_archivo"));
        d.setIdArea((Integer)rs.getObject("id_area"));
        d.setAreaNombre(rs.getString("area_nombre"));
        return d;
    }

    public static int countRequireResponseByUser(int userId) throws SQLException {
        String sql = "SELECT COUNT(*) FROM documento " +
                     "WHERE radicado_a = ? AND requiere_respuesta = TRUE AND respondido = FALSE";
        try (Connection c = conexionBD.conectar();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, userId);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getInt(1) : 0;
            }
        }
    }

    public static List<Documento> findRequireResponseByUser(int userId, int offset, int limit) throws SQLException {
        String sql =
          "SELECT d.id, d.titulo, d.tipo, d.numero_radicado, " +
          "       d.id_area, d.recibido_por, d.radicado_a, " +
          "       d.fecha_creacion, d.eliminado, d.es_plantilla, d.requiere_respuesta, d.respondido, " +
          "       d.nombre_archivo, a.nombre AS area_nombre " +
          "  FROM documento d " +
          "  LEFT JOIN area a ON d.id_area = a.id " +
          " WHERE d.radicado_a = ? AND d.requiere_respuesta = TRUE AND d.respondido = FALSE " +
          " ORDER BY d.fecha_creacion DESC LIMIT ? OFFSET ?";
        List<Documento> list = new ArrayList<>();
        try (Connection c = conexionBD.conectar();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setInt(1, userId);
            ps.setInt(2, limit);
            ps.setInt(3, offset);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    list.add(mapRow(rs));
                }
            }
        }
        return list;
    }
}
