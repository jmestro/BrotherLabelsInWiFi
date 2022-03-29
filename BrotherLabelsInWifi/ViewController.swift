//
//  ViewController.swift
//  BrotherLabelsInWifi
//
//  Created by Joe Mestrovich on 3/28/22.
//

import UIKit

class ViewController: UIViewController {
	
	var wiFiDevicesInfo: [BRPtouchDeviceInfo]?
	var networkManager: BRPtouchNetworkManager?
	var selectedDeviceInfo: BRPtouchDeviceInfo?
	
	@IBOutlet weak var devices: UITableView!
	@IBOutlet weak var selectedDevice: UILabel!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		let manager = BRPtouchNetworkManager()
		manager.delegate = self
		manager.isEnableIPv6Search = false
		manager.setPrinterNames(allBrotherPrinters())
		
		self.networkManager = manager
		fillDeviceList(manager: networkManager!)
		
		devices.delegate = self
		devices.dataSource = self
	}

	func fillDeviceList(manager: BRPtouchNetworkManager) {
		manager.startSearch(2)
	}

	@IBAction func imagePrint(_ sender: UIButton) {
		guard let selectedDeviceInfo = selectedDeviceInfo else { return }
			imagePrint(selectedPrinter: selectedDeviceInfo)
		}

		func imagePrint(selectedPrinter: BRPtouchDeviceInfo) {
			let channel = BRLMChannel(wifiIPAddress: selectedPrinter.strIPAddress)
			let openChannelResult = BRLMPrinterDriverGenerator.open(channel)

			guard openChannelResult.error.code == BRLMOpenChannelErrorCode.noError,
				let printerDriver = openChannelResult.driver else {
					print("Channel Error: \(openChannelResult.error.code.rawValue)")
					return
			}

			defer {
				printerDriver.closeChannel()
			}

			let imageURL = Bundle.main.url(forResource: "RedBlackImageSample", withExtension: "png")
			let printerSettings = BRLMQLPrintSettings(defaultPrintSettingsWith: .QL_1110NWB)
			printerSettings?.halftone = .errorDiffusion
			printerSettings?.labelSize = .rollW62
			printerSettings?.autoCut = true

			let error = printerDriver.printImage(with: imageURL!, settings: printerSettings!)
			print("Image Sample print - result code: \(error.code.rawValue)")
	}
	
	@IBAction func pdfPrint(_ sender: Any) {
		guard let selectedDeviceInfo = selectedDeviceInfo else { return }
			
			pdfPrint(selectedPrinter: selectedDeviceInfo)
		}

		func pdfPrint(selectedPrinter: BRPtouchDeviceInfo) {
			let channel = BRLMChannel(wifiIPAddress: selectedPrinter.strIPAddress)
			let openChannelResult = BRLMPrinterDriverGenerator.open(channel)
			
			guard openChannelResult.error.code == BRLMOpenChannelErrorCode.noError,
				let printerDriver = openChannelResult.driver else {
					print("Channel Error: \(openChannelResult.error.code.rawValue)")
					return
			}
			
			defer {
				printerDriver.closeChannel()
			}
			
			let pdfURL = Bundle.main.url(forResource: "PDFSample", withExtension: "pdf")
			let printerSettings = BRLMQLPrintSettings(defaultPrintSettingsWith: .QL_1110NWB)
			printerSettings?.labelSize = .rollW62
			printerSettings?.autoCut = true
			
			let error = printerDriver.printPDF(with: pdfURL!, settings: printerSettings!)
			print("PDFSample print - result code: \(error.code.rawValue)")
	}
	
}

extension ViewController: BRPtouchNetworkDelegate {
	
	func didFinishSearch(_ sender: Any!) {
		guard let foundDevices = networkManager?.getPrinterNetInfo() else { return }
		
		wiFiDevicesInfo = foundDevices as? [BRPtouchDeviceInfo] ?? []
		
		devices.reloadData()
	}
	
	func allBrotherPrinters() -> [String] {
		guard let printNamesURL = Bundle.main.url(forResource: "PrinterList", withExtension: "plist")
			else { fatalError("PrinterList.plist missing in bundle") }
		
		let printersDict = NSDictionary.init(contentsOf: printNamesURL)!
		let printersArray = printersDict.allKeys as! [String]
		
		return printersArray
	}
	
}

extension ViewController: UITableViewDataSource, UITableViewDelegate {
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		guard let deviceCount = wiFiDevicesInfo?.count else { return 0 }
		
		return deviceCount
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		guard
			let devices = wiFiDevicesInfo,
			let cell = tableView.dequeueReusableCell(withIdentifier: "networkDevice")
		else { return UITableViewCell() }
		
		cell.textLabel?.text = devices[indexPath.row].strModelName
		
		return cell
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
			guard let deviceInfo = wiFiDevicesInfo?[indexPath.row] else { return }
			
			selectedDeviceInfo = deviceInfo
				
			selectedDevice.text = deviceInfo.strModelName +
				", Serial #" + deviceInfo.strSerialNumber
		}

}
