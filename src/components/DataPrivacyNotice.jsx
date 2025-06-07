import React from 'react';

export function DataPrivacyNotice({ isVisible, onAccept, onDecline }) {
  if (!isVisible) return null;

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-lg shadow-xl max-w-2xl w-full max-h-[90vh] overflow-y-auto">
        <div className="p-6">
          <h2 className="text-2xl font-bold mb-4 text-gray-900">
            Persónuverndaryfirlýsing
          </h2>
          
          <div className="space-y-4 text-gray-700">
            <p>
              Kópavogsbær tekur persónuvernd alvarlega og fylgir lögum um persónuvernd og 
              vinnslu persónuupplýsinga nr. 90/2018.
            </p>
            
            <h3 className="text-lg font-semibold">Hvaða gögn söfnum við?</h3>
            <ul className="list-disc pl-6 space-y-1">
              <li>Nafn og netfang starfsmanns</li>
              <li>Starfshlutverksgögn (starfsmaður/stjórnandi)</li>
              <li>Atvikaskráningar og markmiðasetningar</li>
              <li>Tímastimplar fyrir skráningar</li>
            </ul>
            
            <h3 className="text-lg font-semibold">Hvernig notum við gögnin?</h3>
            <ul className="list-disc pl-6 space-y-1">
              <li>Til að halda utan um atvik og framvindu</li>
              <li>Til að búa til tölfræði og skýrslur</li>
              <li>Til að tryggja öryggi og gæði þjónustu</li>
              <li>Til að uppfylla lagalegar skyldur</li>
            </ul>
            
            <h3 className="text-lg font-semibold">Réttindi þín</h3>
            <ul className="list-disc pl-6 space-y-1">
              <li>Réttur til aðgangs að þínum gögnum</li>
              <li>Réttur til leiðréttingar</li>
              <li>Réttur til eyðingar (þar sem það á við)</li>
              <li>Réttur til að takmarka vinnslu</li>
            </ul>
            
            <h3 className="text-lg font-semibold">Öryggi gagna</h3>
            <p>
              Öll gögn eru geymd á öruggum gagnagrunni með dulkóðun. Aðgangur er 
              takmarkaður við viðeigandi starfsfólk og allar aðgerðir eru skráðar.
            </p>
            
            <h3 className="text-lg font-semibold">Samband</h3>
            <p>
              Ef þú hefur spurningar um persónuvernd, hafðu samband við: 
              <a href="mailto:personuvernd@kopavogur.is" className="text-indigo-600 hover:text-indigo-800 ml-1">
                personuvernd@kopavogur.is
              </a>
            </p>
          </div>
          
          <div className="flex flex-col sm:flex-row gap-3 mt-6 pt-6 border-t">
            <button
              onClick={onAccept}
              className="flex-1 bg-indigo-600 text-white px-4 py-2 rounded-md hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2"
            >
              Ég samþykki
            </button>
            <button
              onClick={onDecline}
              className="flex-1 bg-gray-300 text-gray-700 px-4 py-2 rounded-md hover:bg-gray-400 focus:outline-none focus:ring-2 focus:ring-gray-500 focus:ring-offset-2"
            >
              Hafna
            </button>
          </div>
        </div>
      </div>
    </div>
  );
}