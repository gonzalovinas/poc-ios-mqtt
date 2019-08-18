//
//  ViewController.swift
//  MQTT-Test
//
//  Created by Lee Dowthwaite on 29/12/2018.
//  Copyright © 2018 Lee Dowthwaite. All rights reserved.
//

import UIKit
import MQTTClient

// This MQTT client lib is a bit confusing in terms of what callbacks etc to use. The best example I found that works is here:
// https://github.com/novastone-media/MQTT-Client-Framework/blob/master/MQTTSwift/MQTTSwift/MQTTSwift.swift

class CircularButton: UIButton {

    
    override func awakeFromNib() {
        self.layer.cornerRadius = 15
        self.layer.masksToBounds = true
        self.layer.borderWidth = 1.0
        self.layer.borderColor = UIColor.blue.cgColor
    }
}

class ClientViewController: UIViewController {

    let MQTT_HOST = "localhost" // or IP address e.g. "192.168.0.194"
    let MQTT_PORT: UInt32 = 1883
    
    @IBOutlet private weak var button: CircularButton!
    @IBOutlet private weak var statusLabel: UILabel!
    
    @IBOutlet weak var textTopico: UITextField!
    @IBOutlet weak var textMensaje: UITextField!
    @IBOutlet weak var textField: UITextField!
    
    @IBOutlet weak var textTopicoOrigen: UITextField!
    
    private var transport = MQTTCFSocketTransport()
    fileprivate var session = MQTTSession()
    fileprivate var completion: (()->())?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.session?.delegate = self
        self.transport.host = MQTT_HOST
        self.transport.port = MQTT_PORT
        session?.transport = transport
        
        updateUI(for: self.session?.status ?? .created)
        session?.connect() { error in
            print("connection completed with status \(String(describing: error))")
            if error != nil {
                self.updateUI(for: self.session?.status ?? .created)
            } else {
               //self.subscribe(self.textTopicoOrigen.text!)
                self.updateUI(for: self.session?.status ?? .error)
            }
        }
    }

    @IBAction func desuscrbirTopico(_ sender: Any) {
    
    self.unsubscribe(self.textTopicoOrigen.text!)
        alerta("Desuscripcion", self.textTopicoOrigen.text!)
    }
    
    private func updateUI(for clientStatus: MQTTSessionStatus) {
        DispatchQueue.main.async {
            switch clientStatus {
                case .connected:
                    self.statusLabel.text = "Conectado a Servidor MQTT"
                    self.button.isEnabled = true
                case .connecting,
                     .created:
                    self.statusLabel.text = "Conectado..."
                    self.button.isEnabled = false
                default:
                    self.statusLabel.text = "Fallo de Conexion"
                   // self.button.isSelected = false
                    self.button.isEnabled = false
            }
        }
    }

    private func subscribe(_ topico: String) {
        self.session?.subscribe(toTopic: topico, at: .exactlyOnce) { error, result in
            print("suscripcion error \(String(describing: error)) result \(result!)")
        }
    } 
    
    private func unsubscribe(_ topico: String) {
        self.session?.unsubscribeTopic(topico)
    }
    
    private func publishMessage(_ message: String, onTopic topic: String) {
        session?.publishData(message.data(using: .utf8, allowLossyConversion: false), onTopic: topic, retain: false, qos: .exactlyOnce)
    }
    
    private func alerta(_ titulo: String, _ mensaje: String) {
        
        let alert = UIAlertController(title: titulo, message: mensaje, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Click", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
        
    }
    
    @IBAction func suscribirPressed(_ sender: Any) {
        self.subscribe(self.textTopicoOrigen.text!)
        alerta("Subscripcion", self.textTopicoOrigen.text!)
    }
    
    @IBAction func buttonPressed(sender: UIButton) {
        
      
        
        guard session?.status == .connected else {
            self.updateUI(for: self.session?.status ?? .error)
            return 
        }
       // let state = !sender.isSelected
        sender.isEnabled = false
        completion = { 
           // sender.isSelected = state
            sender.isEnabled = true
        }
        
        publishMessage( self.textMensaje.text!, onTopic: textTopico.text!)
        
    }
}

extension ClientViewController: MQTTSessionManagerDelegate, MQTTSessionDelegate {

    func newMessage(_ session: MQTTSession!, data: Data!, onTopic topic: String!, qos: MQTTQosLevel, retained: Bool, mid: UInt32) {
        
        if let msg = String(data: data, encoding: .utf8) {
            print("topic \(topic!), msg \(msg)")
      
            alerta("Mensajes Entrante desde: \(topic!)", msg)
            
        }
    }

    func messageDelivered(_ session: MQTTSession, msgID msgId: UInt16) {
        print("delivered")
        DispatchQueue.main.async {
            self.completion?()
        }
    }
}

