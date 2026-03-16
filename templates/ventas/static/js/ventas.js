// static/js/ventas.js

// Variables globales
let cortes = [];
let rollosData = {};

// Función para cargar datos de rollos
function cargarDatosRollos() {
    const dataElement = document.getElementById('rollos-data');
    if (dataElement) {
        try {
            const rollosArray = JSON.parse(dataElement.value);
            rollosArray.forEach(rollo => {
                rollosData[rollo.id_rollo] = {
                    id_tela: rollo.id_tela,
                    nombre_tela: rollo.nombre_tela,
                    codigo_tela: rollo.codigo_tela,
                    numero_rollo: rollo.numero_rollo,
                    color: rollo.nombre_color || 'Sin color',
                    precio: rollo.precio_venta_metro,
                    metros_disponibles: rollo.metros_actuales
                };
            });
            console.log('✅ Rollos cargados:', Object.keys(rollosData).length);
        } catch (e) {
            console.error('❌ Error cargando datos:', e);
        }
    }
}

// Función para actualizar la tabla y los totales
function actualizarTabla() {
    const tbody = document.getElementById('cuerpoTabla');
    if (!tbody) return;
    
    tbody.innerHTML = '';
    
    let totalMetros = 0;
    let subtotal = 0;
    
    cortes.forEach((corte, index) => {
        const subtotalCorte = corte.metros * corte.precio;
        totalMetros += corte.metros;
        subtotal += subtotalCorte;
        
        const fila = document.createElement('tr');
        fila.innerHTML = `
            <td>${corte.nombre_tela} <small class="text-muted">(${corte.codigo_tela})</small>}
            <td>${corte.numero_rollo}}
            <td>${corte.color} <span class="badge bg-secondary" style="background-color: ${corte.color === 'Sin color' ? '#6c757d' : '#0d6efd'};">${corte.color}</span>}
            <td>${corte.metros.toFixed(2)} m}
            <td>$${corte.precio.toFixed(2)}}
            <td class="fw-bold">$${subtotalCorte.toFixed(2)}}
            <td class="text-center">
                <button class="btn btn-sm btn-glass text-danger" onclick="eliminarCorte(${index})">
                    <i class="fas fa-trash"></i>
                </button>
            </td>
        `;
        tbody.appendChild(fila);
    });
    
    // Actualizar totales en tabla
    document.getElementById('totalMetros').textContent = totalMetros.toFixed(2) + ' m';
    document.getElementById('totalSubtotal').textContent = '$' + subtotal.toFixed(2);
    
    // Calcular con descuento
    const descuento = parseFloat(document.getElementById('descuento').value) || 0;
    const total = subtotal - descuento;
    
    // Actualizar resumen
    document.getElementById('resumenSubtotal').textContent = '$' + subtotal.toFixed(2);
    document.getElementById('resumenDescuento').textContent = '$' + descuento.toFixed(2);
    document.getElementById('resumenTotal').textContent = '$' + total.toFixed(2);
    
    // Habilitar/deshabilitar botón finalizar
    const finalizarBtn = document.getElementById('finalizarVenta');
    if (finalizarBtn) {
        finalizarBtn.disabled = cortes.length === 0;
    }
}

// Función para eliminar un corte
window.eliminarCorte = function(index) {
    cortes.splice(index, 1);
    actualizarTabla();
};

// Eventos cuando el DOM está listo
document.addEventListener('DOMContentLoaded', function() {
    
    // Cargar datos de rollos
    cargarDatosRollos();
    
    // Evento para agregar corte
    const agregarCorteBtn = document.getElementById('agregarCorte');
    if (agregarCorteBtn) {
        agregarCorteBtn.addEventListener('click', function() {
            const idRollo = document.getElementById('id_rollo').value;
            const metros = parseFloat(document.getElementById('metros').value);
            
            if (!idRollo) {
                alert('❌ Por favor seleccione un rollo');
                return;
            }
            
            if (!metros || metros <= 0) {
                alert('❌ Por favor ingrese metros válidos');
                return;
            }
            
            const rollo = rollosData[idRollo];
            
            if (!rollo) {
                alert('❌ Rollo no encontrado');
                return;
            }
            
            if (metros > rollo.metros_disponibles) {
                alert(`❌ Solo hay ${rollo.metros_disponibles} metros disponibles`);
                return;
            }
            
            // Verificar si ya existe el rollo en los cortes
            const corteExistente = cortes.find(c => c.id_rollo === parseInt(idRollo));
            if (corteExistente) {
                alert('⚠️ Este rollo ya está en la lista. Si necesita más metros, elimine el corte actual y agregue uno nuevo con la cantidad total.');
                return;
            }
            
            // Agregar corte
            cortes.push({
                id_rollo: parseInt(idRollo),
                id_tela: rollo.id_tela,
                nombre_tela: rollo.nombre_tela,
                codigo_tela: rollo.codigo_tela,
                numero_rollo: rollo.numero_rollo,
                color: rollo.color,
                metros: metros,
                precio: rollo.precio
            });
            
            // Actualizar tabla
            actualizarTabla();
            
            // Limpiar formulario
            document.getElementById('id_rollo').value = '';
            document.getElementById('metros').value = '';
            
            // Mostrar mensaje de éxito
            console.log('✅ Corte agregado:', cortes[cortes.length - 1]);
        });
    }
    
    // Evento para finalizar venta
    const finalizarBtn = document.getElementById('finalizarVenta');
    if (finalizarBtn) {
        finalizarBtn.addEventListener('click', function() {
            if (cortes.length === 0) {
                alert('❌ Agregue al menos un corte antes de finalizar');
                return;
            }
            
            const metodoPago = document.getElementById('metodo_pago').value;
            const descuento = parseFloat(document.getElementById('descuento').value) || 0;
            
            const subtotal = cortes.reduce((sum, corte) => sum + (corte.metros * corte.precio), 0);
            const total = subtotal - descuento;
            
            const datosVenta = {
                total_metros: cortes.reduce((sum, corte) => sum + corte.metros, 0),
                subtotal: subtotal,
                descuento: descuento,
                iva: 0,
                total_pagar: total,
                metodo_pago: metodoPago
            };
            
            console.log('📦 Datos de venta:', datosVenta);
            console.log('✂️ Cortes:', cortes);
            
            document.getElementById('datos_venta').value = JSON.stringify(datosVenta);
            document.getElementById('cortes').value = JSON.stringify(cortes);
            
            document.getElementById('ventaForm').submit();
        });
    }
    
    // Evento para actualizar cuando cambia el descuento
    const descuentoInput = document.getElementById('descuento');
    if (descuentoInput) {
        descuentoInput.addEventListener('input', actualizarTabla);
    }
    
    // Actualizar información del rollo seleccionado
    const selectRollo = document.getElementById('id_rollo');
    if (selectRollo) {
        selectRollo.addEventListener('change', function() {
            const idRollo = this.value;
            const metrosInput = document.getElementById('metros');
            if (idRollo && metrosInput) {
                const rollo = rollosData[idRollo];
                if (rollo) {
                    metrosInput.max = rollo.metros_disponibles;
                    metrosInput.placeholder = `Máx: ${rollo.metros_disponibles} m`;
                }
            } else if (metrosInput) {
                metrosInput.removeAttribute('max');
                metrosInput.placeholder = '';
            }
        });
    }
});