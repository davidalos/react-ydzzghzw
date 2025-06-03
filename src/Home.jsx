import React from 'react';

export default function Home() {
  return (
    <div className="max-w-4xl mx-auto px-4 py-8">
      <div className="bg-white rounded-lg shadow-lg p-8">
        <h1 className="text-3xl font-bold mb-6">Velkomin/n í Atvikaskráningu Kópavogsbæjar</h1>
        
        <section className="mb-8">
          <h2 className="text-2xl font-semibold mb-4">Um kerfið</h2>
          <p className="text-gray-700 mb-4">
            Atvikaskráningarkerfið er hannað til að auðvelda starfsfólki Kópavogsbæjar að halda utan um og skrá atvik 
            sem upp koma í daglegu starfi. Kerfið gerir okkur kleift að fylgjast með framvindu mála, greina mynstur 
            og bregðast við á skilvirkan hátt.
          </p>
        </section>

        <section className="mb-8">
          <h2 className="text-2xl font-semibold mb-4">Persónuvernd</h2>
          <div className="space-y-4 text-gray-700">
            <p>
              Öll meðferð persónuupplýsinga í kerfinu er í samræmi við lög um persónuvernd og vinnslu 
              persónuupplýsinga nr. 90/2018. Helstu atriði:
            </p>
            <ul className="list-disc pl-6 space-y-2">
              <li>Allar upplýsingar eru geymdar á öruggum gagnagrunni</li>
              <li>Aðgangur að upplýsingum er takmarkaður við viðeigandi starfsfólk</li>
              <li>Persónugreinanlegar upplýsingar eru dulkóðaðar</li>
              <li>Gögn eru geymd í samræmi við varðveisluskyldu opinberra gagna</li>
            </ul>
          </div>
        </section>

        <section className="mb-8">
          <h2 className="text-2xl font-semibold mb-4">Helstu eiginleikar</h2>
          <div className="grid md:grid-cols-2 gap-6">
            <div className="bg-gray-50 p-4 rounded-lg">
              <h3 className="text-lg font-medium mb-2">Atvikaskráning</h3>
              <p className="text-gray-600">
                Skráðu atvik með ítarlegum upplýsingum, flokkun og eftirfylgni.
              </p>
            </div>
            <div className="bg-gray-50 p-4 rounded-lg">
              <h3 className="text-lg font-medium mb-2">Markmiðasetning</h3>
              <p className="text-gray-600">
                Settu markmið og fylgstu með framvindu þeirra yfir tíma.
              </p>
            </div>
            <div className="bg-gray-50 p-4 rounded-lg">
              <h3 className="text-lg font-medium mb-2">Tölfræði og yfirlit</h3>
              <p className="text-gray-600">
                Fáðu yfirsýn yfir tölfræði og þróun mála með myndrænum hætti.
              </p>
            </div>
            <div className="bg-gray-50 p-4 rounded-lg">
              <h3 className="text-lg font-medium mb-2">Samvinna</h3>
              <p className="text-gray-600">
                Deildu upplýsingum og vinnið saman að lausnum.
              </p>
            </div>
          </div>
        </section>

        <section>
          <h2 className="text-2xl font-semibold mb-4">Hafðu samband</h2>
          <p className="text-gray-700">
            Ef þú hefur spurningar eða ábendingar varðandi kerfið, vinsamlegast hafðu samband við 
            kerfisstjóra í gegnum tölvupóst: 
            <a href="mailto:support@kopavogur.is" className="text-indigo-600 hover:text-indigo-800 ml-1">
              support@kopavogur.is
            </a>
          </p>
        </section>
      </div>
    </div>
  );
}