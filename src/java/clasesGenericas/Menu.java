package clasesGenericas;

import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.stream.Collectors;


public class Menu {
    private static final Map<String, Integer> usage = new ConcurrentHashMap<>();

    private static final Map<String, String> labels = Map.ofEntries(
        Map.entry("inicio.jsp",             "Inicio"),
        Map.entry("documento.jsp",          "Documentos"),
        Map.entry("documentoPlantilla.jsp", "Plantillas"),
        Map.entry("buscarDocumento.jsp",    "Búsquedas"),
        Map.entry("versionDocumento.jsp",   "Versiones"),
        Map.entry("papelera.jsp",           "Papelera"),
        Map.entry("auditoria.jsp",          "Auditoría"),
        Map.entry("usuario.jsp",            "Usuarios"),
        Map.entry("rol.jsp",                "Roles"),
        Map.entry("etiqueta.jsp",           "Etiquetas"),
        Map.entry("permiso.jsp",            "Permisos"),
        Map.entry("preferencia.jsp",        "Preferencias")
    );


    public static void recordUse(String url) {
        if (labels.containsKey(url)) {
            usage.merge(url, 1, Integer::sum);
        }
    }


    public static List<Map<String, String>> findTopShortcuts() {
        return labels.keySet().stream()
            .filter(u -> usage.getOrDefault(u, 0) > 0)
            .sorted((a, b) -> Integer.compare(
                usage.getOrDefault(b, 0),
                usage.getOrDefault(a, 0)
            ))
            .limit(4)
            .map(u -> {
                Map<String, String> m = new HashMap<>();
                m.put("url",   u);
                m.put("label", labels.get(u));
                return m;
            })
            .collect(Collectors.toList());
    }
}
