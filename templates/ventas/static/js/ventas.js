// static/js/ventas.js

// Variables globales
let cortes = [];
let rollosData = {};

// Función para cargar datos desde el textarea oculto
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
            console.log('Rollos cargados:', Object.keys(rollosData).length);
        } catch (e) {
            console.error('Error cargando datos:', e);
        }
    }
}

// Función para actualizar la tabla
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
            <td>${corte.nombre_tela}</td>
            <td>${corte.numero_rollo}</td>
            <td>${corte.color}</td>
            <td>${corte.metros.toFixed(2)} m</td>
            <td>$${corte.precio.toFixed(2)}</td>
            <td>$${subtotalCorte.toFixed(2)}</td>
            <td>
                <button class="btn btn-sm btn-danger" onclick="eliminarCorte(${index})">
                    <i class="fas fa-trash"></i>
                </button>
            </td>
        `;
        tbody.appendChild(fila);
    });
    
    const totalMetrosEl = document.getElementById('totalMetros');
    const totalPagarEl = document.getElementById('totalPagar');
    const resumenSubtotal = document.getElementById('resumenSubtotal');
    const resumenDescuento = document.getElementById('resumenDescuento');
    const resumenTotal = document.getElementById('resumenTotal');
    const finalizarVenta = document.getElementById('finalizarVenta');
    
    if (totalMetrosEl) totalMetrosEl.textContent = totalMetros.toFixed(2) + ' m';
    
    const descuento = parseFloat(document.getElementById('descuento')?.value) || 0;
    const total = subtotal - descuento;
    
    if (resumenSubtotal) resumenSubtotal.textContent = '$' + subtotal.toFixed(2);
    if (resumenDescuento) resumenDescuento.textContent = '$' + descuento.toFixed(2);
    if (resumenTotal) resumenTotal.textContent = '$' + total.toFixed(2);
    if (totalPagarEl) totalPagarEl.textContent = '$' + total.toFixed(2);
    
    // Habilitar/deshabilitar botón finalizar
    if (finalizarVenta) finalizarVenta.disabled = cortes.length === 0;
}

// Función para eliminar un corte
window.eliminarCorte = function(index) {
    cortes.splice(index, 1);
    actualizarTabla();
};

// Configurar eventos cuando el DOM esté listo
document.addEventListener('DOMContentLoaded', function() {
    
    // Cargar datos de rollos
    cargarDatosRollos();
    
    // Evento para agregar corte
    const agregarCorte = document.getElementById('agregarCorte');
    if (agregarCorte) {
        agregarCorte.addEventListener('click', function() {
            const idRollo = document.getElementById('id_rollo').value;
            const metros = parseFloat(document.getElementById('metros').value);
            
            if (!idRollo) {
                alert('Seleccione un rollo');
                return;
            }
            
            if (!metros || metros <= 0) {
                alert('Ingrese metros válidos');
                return;
            }
            
            const rollo = rollosData[idRollo];
            
            if (!rollo) {
                alert('Rollo no encontrado');
                return;
            }
            
            if (metros > rollo.metros_disponibles) {
                alert(`Solo hay ${rollo.metros_disponibles} metros disponibles`);
                return;
            }
            
            // Verificar si ya existe el rollo en los cortes
            const corteExistente = cortes.find(c => c.id_rollo === parseInt(idRollo));
            if (corteExistente) {
                alert('Este rollo ya está en la lista');
                return;
            }
            
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
            
            actualizarTabla();
            
            // Limpiar formulario
            document.getElementById('id_rollo').value = '';
            document.getElementById('metros').value = '';
        });
    }
    
    // Evento para finalizar venta
    const finalizarVenta = document.getElementById('finalizarVenta');
    if (finalizarVenta) {
        finalizarVenta.addEventListener('click', function() {
            if (cortes.length === 0) {
                alert('Agregue al menos un corte');
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
            
            document.getElementById('datos_venta').value = JSON.stringify(datosVenta);
            document.getElementById('cortes').value = JSON.stringify(cortes);
            
            document.getElementById('ventaForm').submit();
        });
    }
    
    // Evento para actualizar cuando cambia el descuento
    const descuento = document.getElementById('descuento');
    if (descuento) {
        descuento.addEventListener('input', actualizarTabla);
    }
    
    // Actualizar información del rollo seleccionado
    const idRollo = document.getElementById('id_rollo');
    if (idRollo) {
        idRollo.addEventListener('change', function() {
            const idRolloValue = this.value;
            const metrosInput = document.getElementById('metros');
            if (idRolloValue && metrosInput) {
                const rollo = rollosData[idRolloValue];
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