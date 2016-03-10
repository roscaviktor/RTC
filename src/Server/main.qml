import QtQuick 2.0
import QtWebSockets 1.0
import QtQuick.Window 2.2
import QtQuick.Controls 1.4

//import "qrc://../shared/Circle.qml" as Circle

Window {
	title: "RTC Server"
	width: 480
	height: width + 140
	visible: true

	property var socket
	property int socketStatus : 0
	property int synchronizations: 0
	property int alfa : 0
	property double pi : 3.14159265
	property double xOrigine : 0
	property double yOrigine : 0
	property double xPrevious : 0
	property double yPrevious : 0
	property double slope : 0
	property double steps : 0
	property bool runningStatus: false

	function validate(message) {
		var dist = Math.sqrt(Math.pow(circle.x - greenCircle.x, 2) + Math.pow(circle.y - greenCircle.y, 2))
		if(dist > maxdistSlider.value){
			xPrevious = greenCircle.x = circle.x;
			yPrevious = greenCircle.y = circle.y;
			slope = -1 / ((yOrigine - greenCircle.y)/(xOrigine - greenCircle.x));
			steps = (alfa > 180 ? 1.0 : -1.0) * pi * radiusSlider.value / 360.0;
			if(socketStatus){
				var socketMessage = {
					"xCircle": circle.x,
					"yCircle": circle.y,
					"xOrigine": xOrigine,
					"yOrigine": yOrigine,
					"steps": steps,
					"speed" : speedSlider.value
				};
				var data = JSON.stringify(socketMessage);
				socket.sendTextMessage(data);
				synchronizations++;
			}
		}
		greenCircle.x += steps;
		greenCircle.y = yPrevious - slope * (xPrevious - greenCircle.x);
	}

	Timer {
		id: timer
		interval: 101 - speedSlider.value
		running: runningStatus
		repeat: true
		onTriggered: {
			xOrigine = workspace.width / 2;
			yOrigine = workspace.height / 2;
			if(++alfa > 360){
				alfa = 0;
			}
			circle.x = Math.cos(alfa * pi / 180) * radiusSlider.value + xOrigine;
			circle.y = Math.sin(alfa * pi / 180) * radiusSlider.value + yOrigine;
			validate();
		}
	}

	WebSocketServer {
		id: server
		listen: false
		onClientConnected: {
			socket = webSocket;

			webSocket.onTextMessageReceived.connect(function(message) {
				console.log(qsTr("Server received message: %1").arg(message));
				if(message === "stop"){
					startButton.text = "Start";
					runningStatus = false;
				}else if(message === "start"){
					startButton.text = "Stop";
					runningStatus = true
				}
				socketStatus = 1;
			});

		}
		onErrorStringChanged: {
			socketStatus = 0;
			console.log(qsTr("Server error: %1").arg(errorString));
		}

	}


	Column{
		anchors.fill: parent

		Rectangle{
			color: "black"
			width: parent.width
			height: 110
			Rectangle{
				id: toolbar
				color: parent.color
				width: parent.width - 20
				height: parent.height - 10
				anchors.horizontalCenter: parent.horizontalCenter
				anchors.verticalCenter: parent.verticalCenter
				Row{
					anchors.fill: parent
					spacing: 20
					Column{
						height: parent.height
						width: parent.width / 2 - 10

						Button{
							id: startButton
							text: "Start"
							onClicked: {
								if(runningStatus){
									startButton.text = "Start";
									runningStatus = false;
									socket.sendTextMessage("stop");
								}else{
									startButton.text = "Stop";
									runningStatus = true;
									socket.sendTextMessage("start");
								}
							}
						}
						Text{
							text: "Total Socket Messages: " + synchronizations;
							color: "#fff"
							width: parent.width
						}
					}
					Column{
						height: parent.height
						width: parent.width / 2 - 10
						Text{
							color: "#fff"
							width: parent.width
							text: "Radius: " + radiusSlider.value.toFixed(2) + "/" + radiusSlider.maximumValue
						}
						Slider {
							id: radiusSlider
							width: parent.width
							value: 200
							maximumValue: 500
						}

						Text{
							color: "#fff"
							width: parent.width
							text: "Maximum Distance: " + maxdistSlider.value.toFixed(2) + "/" + maxdistSlider.maximumValue
						}
						Slider {
							id: maxdistSlider
							width: parent.width
							value: 30
							maximumValue: 100
						}


						Text{
							color: "#fff"
							width: parent.width
							text: "Speed: " + speedSlider.value.toFixed(2) + "/" + speedSlider.maximumValue
						}
						Slider {
							id: speedSlider
							width: parent.width
							value: 50
							maximumValue: 100
							minimumValue: 1
						}
					}
				}
			}
		}
		Rectangle{
			id: workspace
			color: "lightgray"
			width: parent.width
			height: parent.height - toolbar.height - copyright.height

			Rectangle{
				id: circle
				height: 10
				width: height
				radius: height / 2
				color: "blue"
				x: workspace.width / 2
				y: workspace.height / 2
			}

			Text{
				color: "blue"
				font.pixelSize: 10
				x: circle.x + circle.width
				y: circle.y + circle.height
				text: "(" + circle.x.toFixed(2) + "," + circle.y.toFixed(2) + ")"
			}

			Rectangle{
				id: greenCircle
				height: 10
				width: height
				radius: height / 2
				color: "green"
				x: workspace.width / 2
				y: workspace.height / 2
			}

			Text{
				color: "green"
				font.pixelSize: 10
				x: greenCircle.x - width
				y: greenCircle.y + greenCircle.height
				text: "(" + greenCircle.x.toFixed(2) + "," + greenCircle.y.toFixed(2) + ")"
			}
		}
		Rectangle{
			id: copyright
			color: "#000"
			width: parent.width
			height: 30
			Text{
				color: "#fff"
				text: "© Victor Rosca, 2015"
			}
		}
	}

	Component.onCompleted: {
		server.port = 9000;
		server.listen = true
		console.log("Server listen at: " + server.url);
	}
}
