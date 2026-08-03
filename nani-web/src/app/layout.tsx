import type { Metadata } from "next";
import Script from "next/script";
import "./globals.css";

export const metadata: Metadata = {
  metadataBase: new URL("https://getnani.online"),
  title: "Nani — Anime Sound Effects for Mac",
  description: "A hyper-native macOS utility designed to inject pure anime joy into the mundane act of connecting cables.",
  keywords: ["macOS", "anime", "sound effects", "mac utility", "Nani", "otaku", "custom sounds"],
  openGraph: {
    title: "Nani — Anime Sound Effects for Mac",
    description: "A hyper-native macOS utility designed to inject pure anime joy into the mundane act of connecting cables.",
    url: "https://getnani.online",
    siteName: "Nani",
    images: [
      {
        url: "/assets/app-icon.png",
        width: 512,
        height: 512,
        alt: "Nani App Icon",
      },
    ],
    locale: "en_US",
    type: "website",
  },
  twitter: {
    card: "summary_large_image",
    title: "Nani — Anime Sound Effects for Mac",
    description: "A hyper-native macOS utility designed to inject pure anime joy into the mundane act of connecting cables.",
    images: ["/assets/app-icon.png"],
    creator: "@iamvibecoder",
  },
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en" data-theme="light" suppressHydrationWarning>
      <head>
        <meta name="theme-color" content="#F4F4F0" />
      </head>
      <body>
        {/* Google tag (gtag.js) */}
        <Script async src="https://www.googletagmanager.com/gtag/js?id=G-MB8SLPR2FX" strategy="afterInteractive" />
        <Script id="google-analytics" strategy="afterInteractive">
          {`
            window.dataLayer = window.dataLayer || [];
            function gtag(){dataLayer.push(arguments);}
            gtag('js', new Date());
          
            gtag('config', 'G-MB8SLPR2FX');
          `}
        </Script>
        {children}
      </body>
    </html>
  );
}
