/**
 * Pr&aacute;ctricas de Sistemas Inform&aacute;ticos II
 * VisaCancelacionJMSBean.java
 */

package ssii2.visa;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import javax.ejb.EJBException;
import javax.ejb.MessageDriven;
import javax.ejb.MessageDrivenContext;
import javax.ejb.ActivationConfigProperty;
import javax.jms.MessageListener;
import javax.jms.Message;
import javax.jms.TextMessage;
import javax.jms.JMSException;
import javax.annotation.Resource;
import java.util.logging.Logger;

/**
 * @author jaime
 */
@MessageDriven(mappedName = "jms/VisaPagosQueue")
public class VisaCancelacionJMSBean extends DBTester implements MessageListener {
  static final Logger logger = Logger.getLogger("VisaCancelacionJMSBean");
  @Resource
  private MessageDrivenContext mdc;

  // Definir UPDATE sobre la tabla pagos para poner
  // codRespuesta a 999 dado un código de autorización
  private static final String UPDATE_CANCELA_QRY =
      "update pago" + 
      " set codrespuesta=999" +
      " where idautorizacion=?";

  private static final String RECTIFICAR_SALDO_QRY =
    "update tarjeta" +
    " inner join pago on tarjeta.numerotarjeta = pago.numerotarjeta" +
    " set saldo = saldo + pago.importe" +
    " where pago.idautorizacion=?";

  public VisaCancelacionJMSBean() {
  }

  private boolean ejecutarConsultaActualizacion(String consulta) {
    PreparedStatement pstmt = con.prepareStatement(UPDATE_CANCELA_QRY);
    pstmt.setInt(1, msg.getText());
    boolean exito = !pstmt.execute() && pstmt.getUpdateCount() == 1;
    if (!exito) {
      logger.error("Ha ocurrido un error al ejecutar la consulta");
    }
    ptsmt.close();
    return exito;
  }

  // TODO : Método onMessage de ejemplo
  // Modificarlo para ejecutar el UPDATE definido más arriba,
  // asignando el idAutorizacion a lo recibido por el mensaje
  // Para ello conecte a la BD, prepareStatement() y ejecute correctamente
  // la actualización
  public void onMessage(Message inMessage) {
      TextMessage msg = null;

      try {
          if (inMessage instanceof TextMessage) {
              msg = (TextMessage) inMessage;
              logger.info("MESSAGE BEAN: Message received: " + msg.getText());

              // [EJ11]
              ejecutarConsultaActualizacion(UPDATE_CANCELA_QRY);
              ejecutarConsultaActualizacion(RECTIFICAR_SALDO_QRY);
              // [/EJ11]
              
          } else {
              logger.warning(
                      "Message of wrong type: "
                      + inMessage.getClass().getName());
          }
      } catch (JMSException e) {
          e.printStackTrace();
          mdc.setRollbackOnly();
      } catch (Throwable te) {
          te.printStackTrace();
      }
  }


}
