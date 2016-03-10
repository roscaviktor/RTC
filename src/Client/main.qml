import QtQuick 2.0
import QtWebSockets 1.0
import QtQuick.Window 2.2
import QtQuick.Controls 1.4

Window {
	title: "RTC Client"
	width: 480
	height: width + 130
	visible:  true

	property double pi : 3.14159265
	property double xOrigine : 0
	property double yOrigine : 0
	property double slope : 0
	property double steps : 0
	property double xPrevious : 0
	property double yPrevious : 0
	property int synchronizations: 0
	property bool runningStatus: false
	property string socketMessage: ""

	function update(message) {
		socketMessage = message;
		if(message === "stop"){
			startButton.text = "Start";
			runningStatus = false;
			socket.sendTextMessage("hello");
		} else if(message === "start"){
			startButton.text = "Stop";
			runningStatus = true;
			socket.sendTextMessage("hello");
		}else{
			var obj = JSON.parse(message);
			greenCircle.x = xPrevious = obj.xCircle;
			greenCircle.y = yPrevious = obj.yCircle;
			xOrigine = obj.xOrigine;
			yOrigine = obj.yOrigine;
			steps = obj.steps;
			timer.interval = 101 - obj.speed
			slope = -1 / ((yOrigine - greenCircle.y)/(xOrigine - greenCircle.x));
			++synchronizations;
		}
	}

	Timer {
		id: timer
		interval: 20
		running: runningStatus
		repeat: true
		onTriggered: {
			greenCircle.x += steps;
			greenCircle.y = yPrevious - slope * (xPrevious - greenCircle.x);
		}
	}

	WebSocket {
		id: socket
		url: "ws://127.0.0.1:9000"
		active: true
		onTextMessageReceived: update(message)
		onStatusChanged: {
			if (socket.status == WebSocket.Error) {
				console.log(qsTr("Client error: %1").arg(socket.errorString));
			} else if (socket.status == WebSocket.Closed) {
				console.log(qsTr("Client socket closed."));
			}
		}
	}


	Column{
		anchors.fill: parent

		Rectangle{
			color: "black"
			width: parent.width
			height: 100
			Rectangle{
				id: toolbar
				color: parent.color
				width: parent.width - 20
				height: parent.height - 10
				anchors.horizontalCenter: parent.horizontalCenter
				anchors.verticalCenter: parent.verticalCenter
				Column{
					anchors.fill: parent
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
						text: "Total socket messages: " + synchronizations;
						color: "#fff"
						width: parent.width
					}
					Text{
						text: "Server host: " + socket.url;
						color: "#fff"
						width: parent.width
					}
					Text{
						text: "Last message: " + socketMessage;
						color: "#fff"
						width: parent.width
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
}

