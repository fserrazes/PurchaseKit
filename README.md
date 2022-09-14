# PurchaseKit

<p>
    <img src="https://github.com/fserrazes/PurchaseKit/actions/workflows/CI.yml/badge.svg" />
    <a href="https://github.com/apple/swift-package-manager">
      <img src="https://img.shields.io/badge/spm-compatible-brightgreen.svg?style=flat" />
    </a>
    <img src="https://img.shields.io/badge/iOS-15.0+-orange.svg" />
    <img src="https://img.shields.io/badge/macOS-12.0+-orange.svg" />
    <img src="https://img.shields.io/badge/watchOS-8.0+-orange.svg" />
    <img src="https://img.shields.io/badge/tvOS-15.0+-orange.svg" />
</p>

This is a Swift cross-platform package to use in-app purchase. This framework provides a lightweight wrapper around StoreKit2.

## Funcionalities

* Support **only** for Consumable and Non Consumable products.
* Transaction state changes are listen using the internal transaction listener to provide up-to-date content while the app is running.
* Request the products to display in your app from the App Store, using ``requestProduct()``.
* Purchase your in-app products from the App Store using ``purchase(productId:)``.
* Restore Purchase to sync user previous purchases using ``restore()``.
* Transaction entitlements are verifiy to unlock the purchased content. 

# Requirements

The latest version of PurchaseKit requires:
- Xcode 13.2+

| Platform | Minimum target |
| --- | --- |
| iOS | 15.0+ |
| macOS | 12.0+ |
| watchOS | 8.0+ |
| tvOS | 15.0+ |

# Installation

## Swift Package Manager

Using SPM add the following to your dependencies

'PurchaseKit', 'main', 'https://github.com/fserrazes/PurchaseKit.git'

# How to use? 

## Preparations

    1. Define a set of Strings that hold **ProductIds** for the products you want to sell.
    ProductIds are generally in reverse domain form (“com.your-company.your-product”).
    These ids will match the product ids you define in App Store Connect.
    
    2. Add the StoreKit framework by selecting the app target, General tab.
    In the **Framework, Libraries, and Embedded Content** click +
    
    3. Create the StoreKit Configuration file in your project.
    (Select File > New > File and choose the StoreKit Configuration File template).
    **Note: The Product ID should match with you define set of Strings (item 1.)**
    
    3. Add the in-app purchase capability by selecting the app target and
    **Signing & Capabilities**, then click +
    
    4. Enable StoreKit testing in Xcode (it’s disabled by default).
    (Select Product > Scheme > Edit Scheme. Now select Run and the Options tab. 
    Than select your configuration file from the StoreKit Configuration list).
    
    
## Configure the PurchaseKit service.

This is the entry point for Purchasekit.framework.
    
```swift
import SwiftUI
import PurchaseKit

@main
struct Main: App {
    private var store: StoreViewModel
    private let productIds: [String] = [com.your-company.your-product-1, com.your-company.your-product-2]
    
    init() {
        let service = Purchases.configure(with: productIds)
        self.store = StoreViewModel(service: service)
    }
    
    var body: some Scene {
        WindowGroup {
            StoreView()
                .environmentObject(store)
        }
    }
}

```

## Create StoreViewModel (suggestion)

This class helps to isolate the concrete implementation from PurchaseKit (for simplicity, in this sample is partial isolated).

```swift
import SwiftUI
import PurchaseKit

final class StoreViewModel: ObservableObject {
    @Published private (set) var products: [StoreProduct] = []

    private var service: PurchasesProtocol
    
    init(service: PurchasesProtocol) {
        self.service = service
        self.service.delegate = self
        
        Task {
            // During store initialization, request products from the App Store.
            await requestProducts()
        }
    }
    
    @MainActor
    public func requestProducts() async {
        let result = await service.requestProducts()
        if case let .success(products) = result {
            self.products = products
        }
    }
    
    @MainActor
    public func purchase(productId: String) async {
        guard let result = try? await service.purchase(productId: productId) else { return }
        if result, let index = products.firstIndex(where: { $0.id == productId }) {
            products[index].isPurchased = result
        }
    }
    
    public func restore() async {
        await service.restore()
    }
}

extension StoreViewModel: PurchasesDelegate {
    func didFinishedPurchases(product: StoreProduct) {
        DispatchQueue.main.async {
            if let index = self.products.firstIndex(where: { $0.id == product.id }) {
                self.products[index].isPurchased = true
                // Add other update stuff here ...
            }
        }
    }
}  
```

## Request products and Purchases

This method will return all products mapped to ``StoreProduct`` model. 
The products listed starts with purchases status equals **false**. The update status will be triger by ``didFinishedPurchases(product: StoreProduct)`` delegate.

```swift
import SwiftUI

struct StoreView: View {
    @EnvironmentObject private var store: StoreViewModel
    
    var body: some View {
        VStack {
            ForEach(0 ..< store.products.count, id: \.self) { index in
                Button(action: { Task { await store.purchase(productId: store.products[index].id) } }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(store.products[index].displayName)
                                .font(.title2)
                            HStack {
                                Text(store.products[index].description)
                                    .multilineTextAlignment(.leading)
                                Spacer()
                                if store.products[index].isPurchased {
                                    Image(systemName: "checkmark.circle.fill")
                                        .imageScale(.large)
                                        .foregroundColor(.green)
                                        .font(Font.title)
                                } else {
                                    Text(store.products[index].displayPrice)
                                        .foregroundColor(.white)
                                        .frame(width: 70)
                                        .padding(6)
                                        .background(.blue)
                                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                }
                            }
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(product.isPurchased)
            }
        }
    }
}
```

## Restore Purchase

This call displays a system prompt that asks users to authenticate with their App Store credentials.

Note: Call this function only in response to an explicit user action, such as tapping a button.

```swift
import SwiftUI

struct StoreView: View {
    @EnvironmentObject private var store: StoreViewModel
    
    var body: some View {
        VStack {
            Button(action: {
                Task {
                    await store.restore()
                }
            }) {
                HStack {
                    Image(systemName: "arrow.triangle.2.circlepath")
                    Text("Restore Purchases")
                }
                .font(.title2)
                .foregroundColor(.white)
                .padding()
                .frame(width: 300, height: 50, alignment: .center)
                .background(Color.blue)
                .cornerRadius(10.0)
            }
        }
    }
}
```

## Documentation

+ [In-App Purchase Overview](https://developer.apple.com/in-app-purchase/) (Apple)
* [In-App Purchase](https://developer.apple.com/documentation/storekit/in-app_purchase) (Apple)
