const { app, remote, BrowserWindow } = require('electron')
const path = require('path')

app.commandLine.appendSwitch("disable-features", "OutOfBlinkCors")

const filter = {
  urls: ['*://*.google.com/*']
};

function createWindow() {
  const win = new BrowserWindow({
    width: 800,
    height: 600,
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      nodeIntegration: true,
      webSecurity: false // TO REENABLE TO ENABLE CORS
    }
  })
  if (process.env.MODE === 'development') {
    win.loadURL('http://localhost:3000')
    win.webContents.openDevTools()
  } else win.loadFile(path.join(__dirname, '../dist/index.html'))

  // Modify the origin for all requests to the following urls.
  /*
  const session = win.webContents.session
  const filter = {
    urls: ['http://example.com/*']
  }

  session.defaultSession.webRequest.onBeforeSendHeaders(
    filter,
    (details, callback) => {
      console.log(details)
      details.requestHeaders['Origin'] = 'http://example.com'
      callback({ requestHeaders: details.requestHeaders })
    }
  )

  session.defaultSession.webRequest.onHeadersReceived(
    filter,
    (details, callback) => {
      console.log(details)
      details.responseHeaders['Access-Control-Allow-Origin'] = [
        'capacitor-electron://-'
      ]
      callback({ responseHeaders: details.responseHeaders })
    }
  )
  */
}

app.whenReady().then(() => {
  createWindow()

  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) {
      createWindow()
    }
  })
})

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') {
    app.quit()
  }
})
